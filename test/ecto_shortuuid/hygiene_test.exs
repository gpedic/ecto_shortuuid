defmodule Ecto.ShortUUID.HygieneTest do
  use ExUnit.Case, async: true

  defmodule Foo.UUID do
    def owner, do: :foo
  end

  # A type module with its own `UUID` alias, declared before and after `use`.
  defmodule AliasBefore do
    alias Ecto.ShortUUID.HygieneTest.Foo.UUID
    use Ecto.ShortUUID.Builder, encoder: ShortUUID

    def uuid_owner, do: UUID.owner()
  end

  defmodule AliasAfter do
    use Ecto.ShortUUID.Builder, encoder: ShortUUID
    alias Ecto.ShortUUID.HygieneTest.Foo.UUID

    def uuid_owner, do: UUID.owner()
  end

  test "use Ecto.ShortUUID.Builder does not override the caller's aliases" do
    assert AliasBefore.uuid_owner() == :foo
    assert AliasAfter.uuid_owner() == :foo
  end

  test "only the t/0 type is defined in the caller" do
    {:ok, types} = Code.Typespec.fetch_types(Ecto.ShortUUID)

    assert [t: 0] ==
             for({kind, {name, _, args}} <- types, kind == :type, do: {name, length(args)})
  end
end
