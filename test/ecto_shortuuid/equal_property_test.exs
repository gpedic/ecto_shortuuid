defmodule Ecto.ShortUUID.EqualPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  if Code.ensure_loaded?(ShortUUID.Builder) do
    defmodule Base58 do
      use ShortUUID.Builder, alphabet: :base58
    end

    defmodule Base58Type do
      use Ecto.ShortUUID.Builder, encoder: Base58
    end
  end

  # Random UUID strings, built from random 128-bit binaries.
  defp uuid_gen do
    map(binary(length: 16), &Ecto.UUID.load!/1)
  end

  # The forms the same ID can take for `type`: its ShortUUID and the
  # UUID in lower, upper or mixed case.
  defp forms(type, uuid) do
    {:ok, short} = type.cast(uuid)

    mixed =
      uuid
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map_join(fn {char, i} -> if rem(i, 2) == 0, do: String.upcase(char), else: char end)

    [short, uuid, String.upcase(uuid), mixed]
  end

  defp form_gen(type) do
    bind(uuid_gen(), fn uuid -> member_of(forms(type, uuid)) end)
  end

  # UUID-shaped but invalid: one hex digit replaced with a non-hex character.
  defp broken_uuid_gen do
    gen all(
          uuid <- uuid_gen(),
          pos <- member_of([0, 5, 9, 14, 20, 35]),
          char <- member_of(~w(g z Z _ !))
        ) do
      String.slice(uuid, 0, pos) <> char <> String.slice(uuid, (pos + 1)..-1//1)
    end
  end

  defp term_gen(type) do
    one_of([
      form_gen(type),
      broken_uuid_gen(),
      binary(),
      binary(length: 16),
      binary(length: 22),
      binary(length: 36),
      string(:alphanumeric, length: 22),
      constant(nil),
      integer(),
      atom(:alphanumeric),
      map_of(atom(:alphanumeric), integer(), max_length: 2)
    ])
  end

  # Pairs of valid IDs (see castable_pair_gen/1) or of two arbitrary terms.
  defp pair_gen(type) do
    one_of([castable_pair_gen(type), tuple({term_gen(type), term_gen(type)})])
  end

  # Pairs of valid IDs in any form, either of the same ID or of two IDs.
  defp castable_pair_gen(type) do
    one_of([
      bind(uuid_gen(), fn uuid ->
        forms = forms(type, uuid)
        tuple({member_of(forms), member_of(forms)})
      end),
      tuple({form_gen(type), form_gen(type)})
    ])
  end

  defp type(name), do: Module.concat(__MODULE__, name)

  for {name, tags} <- [{Ecto.ShortUUID, []}, {Base58Type, [custom_alphabet: true]}] do
    describe "#{inspect(name)}.equal?/2" do
      @describetag tags

      setup do
        type = if unquote(name) == Ecto.ShortUUID, do: Ecto.ShortUUID, else: type(unquote(name))
        %{type: type}
      end

      property "all forms of the same ID are equal", %{type: type} do
        check all(uuid <- uuid_gen()) do
          {:ok, short} = type.cast(uuid)
          upper = String.upcase(uuid)

          assert type.equal?(short, uuid)
          assert type.equal?(uuid, short)
          assert type.equal?(short, upper)
          assert type.equal?(upper, short)
          assert type.equal?(uuid, upper)
        end
      end

      property "is reflexive", %{type: type} do
        check all(term <- term_gen(type)) do
          assert type.equal?(term, term)
        end
      end

      property "is symmetric and never raises", %{type: type} do
        check all({a, b} <- pair_gen(type)) do
          assert is_boolean(type.equal?(a, b))
          assert type.equal?(a, b) == type.equal?(b, a)
        end
      end

      property "agrees with cast/1 when both terms cast", %{type: type} do
        check all({a, b} <- castable_pair_gen(type)) do
          {:ok, cast_a} = type.cast(a)
          {:ok, cast_b} = type.cast(b)
          assert type.equal?(a, b) == (cast_a == cast_b)
        end
      end

      property "different IDs are never equal in any form", %{type: type} do
        check all(
                uuid1 <- uuid_gen(),
                uuid2 <- uuid_gen(),
                uuid1 != uuid2
              ) do
          for a <- forms(type, uuid1), b <- forms(type, uuid2) do
            refute type.equal?(a, b)
          end
        end
      end
    end
  end
end
