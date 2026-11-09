defmodule Ecto.ShortUUIDTest do
  use ExUnit.Case, async: true
  doctest Ecto.ShortUUID

  @test_shortuuid "9VprZJ9U7Tgg2PJ8BfTAek"
  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @test_uuid_upper "2A162EE5-02F4-4701-9E87-72762CBCE5E2"
  @test_uuid_binary <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76,
                      0x2C, 0xBC, 0xE5, 0xE2>>

  # Value of 22 characters from the alphabet that exceeds 128 bits
  @overflow_shortuuid String.duplicate("z", 22)

  # Values none of cast/1, load/1 and dump/1 accept
  @invalid ["", "invalid", nil, 0, 1, <<0>>, false, true, @overflow_shortuuid]

  defmodule Schema do
    use Ecto.Schema

    @primary_key {:id, Ecto.ShortUUID, autogenerate: true}
    embedded_schema do
      field(:ids, {:array, Ecto.ShortUUID})
    end
  end

  describe "cast/1" do
    test "casts ShortUUIDs to themselves" do
      assert {:ok, @test_shortuuid} === Ecto.ShortUUID.cast(@test_shortuuid)
    end

    test "casts UUIDs to ShortUUIDs" do
      assert {:ok, @test_shortuuid} === Ecto.ShortUUID.cast(@test_uuid)
      assert {:ok, @test_shortuuid} === Ecto.ShortUUID.cast(@test_uuid_upper)

      assert {:ok, @test_shortuuid} ===
               Ecto.ShortUUID.cast("2A162ee5-02F4-4701-9e87-72762cBcE5e2")
    end

    test "casts UUIDs of any version" do
      # v1 (time-based)
      assert {:ok, "dtNtDHxdgow74P9DrPcDsM"} ===
               Ecto.ShortUUID.cast("c9aec822-6d99-11ee-b962-0242ac120002")

      # v4 (random)
      assert {:ok, "a6ckmZcnop4qRVD8QVUVJt"} ===
               Ecto.ShortUUID.cast("b44f3c49-0403-4dcd-bd5f-e22ea6d48a4f")
    end

    test "rejects invalid UUIDs" do
      assert :error === Ecto.ShortUUID.cast("fee080d9-3ea4-408b-9c2")
      assert :error === Ecto.ShortUUID.cast("not a uuid")
      assert :error === Ecto.ShortUUID.cast("2a162ee5-02f4-4701-9e87-72762cbce5eZ")
      # Wrong delimiters
      assert :error === Ecto.ShortUUID.cast("2a162ee5_02f4_4701_9e87_72762cbce5e2")
      # Missing sections
      assert :error === Ecto.ShortUUID.cast("c9aec822-6d99-11ee-b962")
      # Too many sections
      assert :error === Ecto.ShortUUID.cast("c9aec822-6d99-11ee-b962-0242ac120002-extra")
    end

    test "rejects malformed ShortUUIDs" do
      # Too short
      assert :error === Ecto.ShortUUID.cast("9VprZJ")
      # Too long
      assert :error === Ecto.ShortUUID.cast(@test_shortuuid <> "extra")
      # Characters outside the alphabet
      assert :error === Ecto.ShortUUID.cast("9VprZJ9U7T/g2PJ8BfTAek")
      assert :error === Ecto.ShortUUID.cast("Invalid$ShortUUID")
      # Value larger than 128 bits
      assert :error === Ecto.ShortUUID.cast(@overflow_shortuuid)
    end

    test "rejects raw 16-byte binaries" do
      assert :error === Ecto.ShortUUID.cast(@test_uuid_binary)
      assert :error === Ecto.ShortUUID.cast(<<0::128>>)
    end

    test "rejects other values" do
      for value <- @invalid do
        assert :error === Ecto.ShortUUID.cast(value), "expected cast(#{inspect(value)}) to fail"
      end
    end
  end

  describe "load/1" do
    test "loads binary UUIDs as ShortUUIDs" do
      assert {:ok, @test_shortuuid} === Ecto.ShortUUID.load(@test_uuid_binary)
    end

    test "raises when loading a string UUID" do
      assert_raise ArgumentError, fn ->
        Ecto.ShortUUID.load(@test_uuid)
      end
    end

    test "rejects binaries that aren't 128 bits" do
      assert :error === Ecto.ShortUUID.load(<<0::120>>)
      assert :error === Ecto.ShortUUID.load(<<0::136>>)
    end

    test "rejects other values" do
      for value <- @invalid do
        assert :error === Ecto.ShortUUID.load(value), "expected load(#{inspect(value)}) to fail"
      end
    end
  end

  describe "dump/1" do
    test "dumps ShortUUIDs" do
      assert {:ok, @test_uuid_binary} === Ecto.ShortUUID.dump(@test_shortuuid)
    end

    test "dumps UUIDs in any case" do
      assert {:ok, @test_uuid_binary} === Ecto.ShortUUID.dump(@test_uuid)
      assert {:ok, @test_uuid_binary} === Ecto.ShortUUID.dump(@test_uuid_upper)
    end

    test "produces the same binary as Ecto.UUID.dump/1" do
      for uuid <- [@test_uuid, @test_uuid_upper, Ecto.UUID.generate()] do
        {:ok, shortuuid} = Ecto.ShortUUID.cast(uuid)
        assert Ecto.UUID.dump(uuid) === Ecto.ShortUUID.dump(uuid)
        assert Ecto.UUID.dump(uuid) === Ecto.ShortUUID.dump(shortuuid)
      end
    end

    test "rejects raw 16-byte binaries" do
      assert :error === Ecto.ShortUUID.dump(@test_uuid_binary)
    end

    test "rejects invalid UUIDs" do
      assert :error === Ecto.ShortUUID.dump("2a162ee5_02f4_4701_9e87_72762cbce5e2")
    end

    test "rejects other values" do
      for value <- @invalid do
        assert :error === Ecto.ShortUUID.dump(value), "expected dump(#{inspect(value)}) to fail"
      end
    end
  end

  describe "embed_as/1" do
    test "returns :self" do
      assert :self === Ecto.ShortUUID.embed_as(:json)
      assert :self === Ecto.ShortUUID.embed_as(:any_value)
    end
  end

  describe "generate/0 and autogenerate/0" do
    test "generate valid 22 character ShortUUIDs" do
      for fun <- [:generate, :autogenerate], _ <- 1..10 do
        shortuuid = apply(Ecto.ShortUUID, fun, [])
        assert <<_::176>> = shortuuid
        assert {:ok, ^shortuuid} = Ecto.ShortUUID.cast(shortuuid)
      end
    end

    test "generate version 4 UUIDs" do
      {:ok, binary} = Ecto.ShortUUID.dump(Ecto.ShortUUID.generate())
      assert <<_::48, 4::4, _::12, 2::2, _::62>> = binary
    end
  end

  describe "type/0" do
    test "returns :uuid" do
      assert :uuid === Ecto.ShortUUID.type()
    end
  end

  describe "round trips" do
    test "UUID -> ShortUUID -> binary -> UUID" do
      {:ok, shortuuid} = Ecto.ShortUUID.cast(@test_uuid)
      {:ok, binary} = Ecto.ShortUUID.dump(shortuuid)
      assert {:ok, @test_uuid} === Ecto.UUID.load(binary)
    end

    test "generated ShortUUID -> binary -> ShortUUID" do
      shortuuid = Ecto.ShortUUID.autogenerate()
      {:ok, binary} = Ecto.ShortUUID.dump(shortuuid)
      assert {:ok, shortuuid} === Ecto.ShortUUID.load(binary)
    end

    test "boundary values" do
      for {uuid, shortuuid, binary} <- [
            {"00000000-0000-0000-0000-000000000000", "2222222222222222222222", <<0::128>>},
            {"ffffffff-ffff-ffff-ffff-ffffffffffff", "oZEq7ovRbLq6UnGMPwc8B5", <<-1::signed-128>>}
          ] do
        assert {:ok, shortuuid} === Ecto.ShortUUID.cast(uuid)
        assert {:ok, binary} === Ecto.ShortUUID.dump(shortuuid)
        assert {:ok, shortuuid} === Ecto.ShortUUID.load(binary)
      end
    end
  end

  describe "Ecto.Changeset.cast/4" do
    test "accepts ShortUUIDs and UUIDs, storing the ShortUUID" do
      for value <- [@test_shortuuid, @test_uuid, @test_uuid_upper] do
        changeset = Ecto.Changeset.cast(%Schema{}, %{"id" => value}, [:id])
        assert changeset.valid?
        assert changeset.changes == %{id: @test_shortuuid}
      end
    end

    test "reports invalid values as invalid" do
      for value <- ["invalid", @overflow_shortuuid, "2a162ee5-02f4-4701-9e87-72762cbce5eZ", 1] do
        changeset = Ecto.Changeset.cast(%Schema{}, %{"id" => value}, [:id])
        refute changeset.valid?
        assert {"is invalid", [type: Ecto.ShortUUID, validation: :cast]} = changeset.errors[:id]
      end
    end
  end

  describe "{:array, Ecto.ShortUUID}" do
    @array_type {:array, Ecto.ShortUUID}

    test "casts mixed UUIDs and ShortUUIDs" do
      assert {:ok, [@test_shortuuid, @test_shortuuid]} ===
               Ecto.Type.cast(@array_type, [@test_uuid, @test_shortuuid])

      assert :error === Ecto.Type.cast(@array_type, [@test_uuid, "invalid"])
    end

    test "dumps and loads" do
      assert {:ok, [@test_uuid_binary]} === Ecto.Type.dump(@array_type, [@test_shortuuid])
      assert {:ok, [@test_shortuuid]} === Ecto.Type.load(@array_type, [@test_uuid_binary])
    end

    test "works in changesets" do
      changeset = Ecto.Changeset.cast(%Schema{}, %{"ids" => [@test_uuid]}, [:ids])
      assert changeset.changes == %{ids: [@test_shortuuid]}

      changeset = Ecto.Changeset.cast(%Schema{}, %{"ids" => ["invalid"]}, [:ids])
      assert {"is invalid", _} = changeset.errors[:ids]
    end
  end

  describe "embedded_dump/3 and embedded_load/3" do
    test "embed the ShortUUID string as is" do
      assert {:ok, @test_shortuuid} ===
               Ecto.Type.embedded_dump(Ecto.ShortUUID, @test_shortuuid, :json)

      assert {:ok, @test_shortuuid} ===
               Ecto.Type.embedded_load(Ecto.ShortUUID, @test_shortuuid, :json)
    end

    test "load embedded UUIDs as ShortUUIDs" do
      assert {:ok, @test_shortuuid} === Ecto.Type.embedded_load(Ecto.ShortUUID, @test_uuid, :json)
    end

    test "reject invalid embedded values" do
      assert :error === Ecto.Type.embedded_load(Ecto.ShortUUID, "invalid", :json)
    end
  end
end
