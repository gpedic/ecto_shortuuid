defmodule Ecto.ShortUUID.CanonicalMarkerTest do
  use ExUnit.Case, async: true

  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"

  # A deliberately lax encoder: it decodes "x" followed by a UUID in any
  # letter case, but only ever encodes to lowercase. encode/1 reports each
  # call to the calling process, so the tests can tell whether cast/1
  # re-encoded the input.
  defmodule LaxEncoder do
    defmacro __using__(info) do
      quote do
        def encode(uuid) do
          send(self(), {:encode, __MODULE__})
          {:ok, "x" <> uuid}
        end

        def decode("x" <> uuid), do: {:ok, String.downcase(uuid)}
        def decode(_), do: {:error, "invalid"}

        if unquote(info) != :none do
          def __shortuuid__, do: unquote(info)
        end
      end
    end
  end

  defmodule Unmarked do
    use LaxEncoder, :none
  end

  defmodule MarkedCanonical do
    use LaxEncoder, %{alphabet: "0-9a-f", base: 16, encoded_length: 37, canonical: true}
  end

  defmodule MarkedNotCanonical do
    use LaxEncoder, %{alphabet: "0-9a-f", base: 16, encoded_length: 37, canonical: false}
  end

  defmodule MarkedWithoutKey do
    use LaxEncoder, %{alphabet: "0-9a-f", base: 16, encoded_length: 37}
  end

  defmodule MarkedNotAMap do
    use LaxEncoder, true
  end

  # Literal encoders, so the canonical flag is decided at compile time.
  defmodule Unmarked.Type, do: use(Ecto.ShortUUID.Builder, encoder: Unmarked)
  defmodule MarkedCanonical.Type, do: use(Ecto.ShortUUID.Builder, encoder: MarkedCanonical)
  defmodule MarkedNotCanonical.Type, do: use(Ecto.ShortUUID.Builder, encoder: MarkedNotCanonical)
  defmodule MarkedWithoutKey.Type, do: use(Ecto.ShortUUID.Builder, encoder: MarkedWithoutKey)
  defmodule MarkedNotAMap.Type, do: use(Ecto.ShortUUID.Builder, encoder: MarkedNotAMap)

  # An encoder only known at runtime can't be inspected when the type is
  # compiled, so it always gets the round trip, marker or not.
  encoder = MarkedCanonical

  defmodule RuntimeType do
    use Ecto.ShortUUID.Builder, encoder: encoder
  end

  @canonical "x" <> @test_uuid
  @non_canonical "x" <> String.upcase(@test_uuid)

  describe "encoder marked canonical: true" do
    test "cast/1 trusts the decoder and doesn't re-encode" do
      assert {:ok, @canonical} == MarkedCanonical.Type.cast(@canonical)
      refute_received {:encode, _}

      # The marker is a promise by the encoder. This one breaks it, which
      # shows that cast/1 no longer checks.
      assert {:ok, @non_canonical} == MarkedCanonical.Type.cast(@non_canonical)
      refute_received {:encode, _}
    end

    test "cast/1 still rejects what the decoder rejects" do
      assert :error == MarkedCanonical.Type.cast("y" <> @test_uuid)
      assert :error == MarkedCanonical.Type.cast("xnot-a-uuid")
    end
  end

  for {type, encoder} <- [
        {Unmarked.Type, Unmarked},
        {MarkedNotCanonical.Type, MarkedNotCanonical},
        {MarkedWithoutKey.Type, MarkedWithoutKey},
        {MarkedNotAMap.Type, MarkedNotAMap},
        {RuntimeType, MarkedCanonical}
      ] do
    describe "#{inspect(type)}" do
      test "cast/1 re-encodes and rejects non-canonical input" do
        type = unquote(type)
        assert {:ok, @canonical} == type.cast(@canonical)
        assert_received {:encode, unquote(encoder)}

        assert :error == type.cast(@non_canonical)
      end
    end
  end

  test "dump/1 only decodes, for every encoder" do
    for type <- [
          Unmarked.Type,
          MarkedCanonical.Type,
          MarkedNotCanonical.Type,
          MarkedWithoutKey.Type,
          MarkedNotAMap.Type,
          RuntimeType
        ] do
      assert Ecto.UUID.dump(@test_uuid) == type.dump(@canonical)
      assert Ecto.UUID.dump(@test_uuid) == type.dump(@non_canonical)
      assert :error == type.dump("xnot-a-uuid")
    end

    refute_received {:encode, _}
  end

  test "load/1 and casting a UUID always encode" do
    {:ok, binary} = Ecto.UUID.dump(@test_uuid)
    assert {:ok, @canonical} == MarkedCanonical.Type.load(binary)
    assert {:ok, @canonical} == MarkedCanonical.Type.cast(String.upcase(@test_uuid))
  end

  test "equal?/2 compares the canonical forms" do
    assert MarkedCanonical.Type.equal?(@canonical, @test_uuid)
    assert MarkedCanonical.Type.equal?(@test_uuid, @canonical)
    refute MarkedCanonical.Type.equal?(@canonical, @non_canonical)
  end

  describe "the default ShortUUID encoder" do
    test "is treated as canonical" do
      {:ok, short} = ShortUUID.encode(@test_uuid)
      assert {:ok, short} == Ecto.ShortUUID.cast(short)
      assert Ecto.UUID.dump(@test_uuid) == Ecto.ShortUUID.dump(short)
    end

    test "rejects input its decoder rejects" do
      {:ok, short} = ShortUUID.encode(@test_uuid)

      # Too long, padded, and above the 128-bit range.
      for input <- [short <> "2", " " <> short, String.duplicate("z", 22)] do
        assert :error == Ecto.ShortUUID.cast(input), "cast(#{inspect(input)})"
      end
    end
  end
end
