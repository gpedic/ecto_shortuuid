defmodule Ecto.ShortUUID.EqualTest do
  use ExUnit.Case, async: true

  @uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @upper_uuid String.upcase(@uuid)
  @short "9VprZJ9U7Tgg2PJ8BfTAek"
  @other_uuid "b44f3c49-0403-4dcd-bd5f-e22ea6d48a4f"
  @other_short "a6ckmZcnop4qRVD8QVUVJt"

  if Code.ensure_loaded?(ShortUUID.Builder) do
    defmodule Base58 do
      use ShortUUID.Builder, alphabet: :base58
    end

    defmodule Base58Type do
      use Ecto.ShortUUID.Builder, encoder: Base58
    end
  end

  defmodule Schema do
    use Ecto.Schema

    @primary_key {:id, Ecto.ShortUUID, autogenerate: true}
    embedded_schema do
      field(:ids, {:array, Ecto.ShortUUID})
    end
  end

  # Resolved at runtime so this file compiles without warnings when
  # ShortUUID.Builder (and therefore Base58Type) doesn't exist.
  defp base58_type, do: Module.concat(__MODULE__, Base58Type)

  test "fixtures are consistent" do
    assert {:ok, @short} == Ecto.ShortUUID.cast(@uuid)
    assert {:ok, @other_short} == Ecto.ShortUUID.cast(@other_uuid)
  end

  describe "Ecto.ShortUUID.equal?/2" do
    test "identical terms are equal" do
      assert Ecto.ShortUUID.equal?(@short, @short)
      assert Ecto.ShortUUID.equal?(@uuid, @uuid)
      assert Ecto.ShortUUID.equal?(nil, nil)
      assert Ecto.ShortUUID.equal?("garbage", "garbage")
    end

    test "a ShortUUID equals the UUID it encodes, in any case and order" do
      assert Ecto.ShortUUID.equal?(@short, @uuid)
      assert Ecto.ShortUUID.equal?(@uuid, @short)
      assert Ecto.ShortUUID.equal?(@short, @upper_uuid)
      assert Ecto.ShortUUID.equal?(@upper_uuid, @short)
    end

    test "UUIDs differing only in case are equal" do
      assert Ecto.ShortUUID.equal?(@uuid, @upper_uuid)
    end

    test "different IDs are not equal" do
      refute Ecto.ShortUUID.equal?(@short, @other_short)
      refute Ecto.ShortUUID.equal?(@short, @other_uuid)
      refute Ecto.ShortUUID.equal?(@uuid, @other_short)
      refute Ecto.ShortUUID.equal?(@uuid, @other_uuid)
    end

    test "invalid values are never equal to valid ones and never raise" do
      refute Ecto.ShortUUID.equal?(nil, @short)
      refute Ecto.ShortUUID.equal?(@uuid, nil)
      refute Ecto.ShortUUID.equal?("garbage", @short)
      refute Ecto.ShortUUID.equal?("garbage", "other garbage")
      refute Ecto.ShortUUID.equal?("2a162ee5-02f4-4701-9e87-72762cbce5eZ", @short)
      refute Ecto.ShortUUID.equal?("2a162ee5-02f4-4701-9e87-72762cbce5eZ", @uuid)

      refute Ecto.ShortUUID.equal?(
               "2a162ee5-02f4-4701-9e87-72762cbce5eZ",
               "2a162ee5-02f4-4701-9e87-72762cbce5eY"
             )
    end

    test "non-binary inputs" do
      assert Ecto.ShortUUID.equal?(1, 1)
      refute Ecto.ShortUUID.equal?(1, "1")
      refute Ecto.ShortUUID.equal?(:a, @short)
      refute Ecto.ShortUUID.equal?(@uuid, %{})
      refute Ecto.ShortUUID.equal?(<<0::128>>, @uuid)
    end
  end

  describe "Ecto.Changeset integration" do
    test "changing the ID to the UUID form of the same ID is not a change" do
      struct = %Schema{id: @short}
      assert Ecto.Changeset.change(struct, id: @uuid).changes == %{}
      assert Ecto.Changeset.change(struct, id: @upper_uuid).changes == %{}
    end

    test "changing to a different ID is a change" do
      struct = %Schema{id: @short}
      assert Ecto.Changeset.change(struct, id: @other_uuid).changes == %{id: @other_uuid}
      assert Ecto.Changeset.change(struct, id: @other_short).changes == %{id: @other_short}
      assert Ecto.Changeset.change(struct, id: nil).changes == %{id: nil}
    end

    test "put_change/3 with the other form of the same ID is not a change" do
      changeset = Ecto.Changeset.change(%Schema{id: @short})
      assert Ecto.Changeset.put_change(changeset, :id, @uuid).changes == %{}
      assert Ecto.Changeset.put_change(changeset, :id, @upper_uuid).changes == %{}

      changeset = Ecto.Changeset.change(%Schema{id: @uuid})
      assert Ecto.Changeset.put_change(changeset, :id, @short).changes == %{}
    end

    test "put_change/3 with a different ID or garbage is a change" do
      changeset = Ecto.Changeset.change(%Schema{id: @short})

      assert Ecto.Changeset.put_change(changeset, :id, @other_short).changes == %{
               id: @other_short
             }

      assert Ecto.Changeset.put_change(changeset, :id, "garbage").changes == %{id: "garbage"}
      assert Ecto.Changeset.put_change(changeset, :id, 1).changes == %{id: 1}
    end

    test "{:array, Ecto.ShortUUID} with other forms of the same IDs is not a change" do
      struct = %Schema{ids: [@short, @other_short]}

      assert Ecto.Changeset.change(struct, ids: [@uuid, String.upcase(@other_uuid)]).changes ==
               %{}

      assert Ecto.Changeset.change(struct, ids: [@other_short, @short]).changes ==
               %{ids: [@other_short, @short]}

      assert Ecto.Changeset.change(struct, ids: [@short]).changes == %{ids: [@short]}
    end

    test "cast/4 still normalizes to the ShortUUID and only records real changes" do
      changeset = Ecto.Changeset.cast(%Schema{id: @short}, %{"id" => @uuid}, [:id])
      assert changeset.valid?
      assert changeset.changes == %{}

      changeset = Ecto.Changeset.cast(%Schema{id: @short}, %{"id" => @other_uuid}, [:id])
      assert changeset.changes == %{id: @other_short}

      changeset = Ecto.Changeset.cast(%Schema{}, %{"ids" => [@uuid, @other_short]}, [:ids])
      assert changeset.changes == %{ids: [@short, @other_short]}

      changeset = Ecto.Changeset.cast(%Schema{id: @short}, %{"id" => "garbage"}, [:id])
      assert {"is invalid", _} = changeset.errors[:id]
    end
  end

  describe "custom alphabet" do
    @describetag :custom_alphabet

    test "the encoded form equals the UUID" do
      type = base58_type()
      {:ok, short} = type.cast(@uuid)

      refute short == @short
      assert type.equal?(short, @uuid)
      assert type.equal?(@upper_uuid, short)
      refute type.equal?(short, @other_uuid)
      # A default-alphabet ShortUUID is not this type's encoding of the UUID
      refute type.equal?(@short, @uuid)
    end
  end
end
