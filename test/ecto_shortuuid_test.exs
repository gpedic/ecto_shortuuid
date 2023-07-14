defmodule Ecto.ShortUUIDTest do
  use ExUnit.Case, async: true
  doctest Ecto.ShortUUID

  @test_shortuuid "9VprZJ9U7Tgg2PJ8BfTAek"
  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @test_uuid_binary <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76,
                      0x2C, 0xBC, 0xE5, 0xE2>>

  describe "cast/1" do
    test "can cast shortuuids" do
      assert {:ok, _} = Ecto.ShortUUID.cast(@test_shortuuid)
    end

    test "can cast UUIDs" do
      assert {:ok, _} = Ecto.ShortUUID.cast(@test_uuid)
    end

    test "can't cast invalid UUIDs" do
      assert :error === Ecto.ShortUUID.cast("fee080d9-3ea4-408b-9c2")
      assert :error === Ecto.ShortUUID.cast("not a uuid")
    end

    test "can't cast invalid formatted UUIDs of correct length" do
      assert :error === Ecto.ShortUUID.cast("2a162ee5_02f4_4701_9e87_72762cbce5e2")
    end

    test "can't cast other types" do
      assert :error === Ecto.ShortUUID.cast("")
      assert :error === Ecto.ShortUUID.cast("invalid")
      assert :error === Ecto.ShortUUID.cast(nil)
      assert :error === Ecto.ShortUUID.cast(0)
      assert :error === Ecto.ShortUUID.cast(1)
      assert :error === Ecto.ShortUUID.cast(<<0>>)
      assert :error === Ecto.ShortUUID.cast(false)
      assert :error === Ecto.ShortUUID.cast(true)
    end
  end

  describe "load/1" do
    test "loads binary UUID" do
      assert {:ok, _} = Ecto.ShortUUID.load(@test_uuid_binary)
    end

    test "loading a string uuid fails" do
      assert_raise ArgumentError, fn ->
        Ecto.ShortUUID.load(@test_uuid)
      end
    end

    test "fails for these values" do
      assert :error === Ecto.ShortUUID.load("")
      assert :error === Ecto.ShortUUID.load("invalid")
      assert :error === Ecto.ShortUUID.load(nil)
      assert :error === Ecto.ShortUUID.load(0)
      assert :error === Ecto.ShortUUID.load(1)
      assert :error === Ecto.ShortUUID.load(<<0>>)
      assert :error === Ecto.ShortUUID.load(false)
      assert :error === Ecto.ShortUUID.load(true)
    end

    test "fails if binary > 128bit" do
      assert :error === Ecto.ShortUUID.load(<<1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
    end

    test "fails if binary < 128bit" do
      assert :error === Ecto.ShortUUID.load(<<1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
    end
  end

  describe "dump/1" do
    test "can dump shortuuid" do
      assert {:ok, _} = Ecto.ShortUUID.dump(@test_shortuuid)
    end

    test "can dump UUID" do
      assert {:ok, @test_uuid_binary} = Ecto.ShortUUID.dump(@test_uuid)
    end

    test "fails to dump binary" do
      assert :error === Ecto.ShortUUID.dump(@test_uuid_binary)
    end

    test "fails to dump invalid formatted UUID of correct length" do
      assert :error === Ecto.ShortUUID.dump("2a162ee5_02f4_4701_9e87_72762cbce5e2")
    end

    test "fails to dump these" do
      assert :error === Ecto.ShortUUID.dump("")
      assert :error === Ecto.ShortUUID.dump("invalid")
      assert :error === Ecto.ShortUUID.dump(nil)
      assert :error === Ecto.ShortUUID.dump(0)
      assert :error === Ecto.ShortUUID.dump(1)
      assert :error === Ecto.ShortUUID.dump(<<0>>)
      assert :error === Ecto.ShortUUID.dump(false)
      assert :error === Ecto.ShortUUID.dump(true)
    end
  end

  describe "embed_as/1" do
    test "returns default :self value" do
      uuid = Ecto.ShortUUID.autogenerate()
      assert :self === Ecto.ShortUUID.embed_as(uuid)
      assert :self === Ecto.ShortUUID.embed_as(:any_value)
    end
  end

  describe "equal?/2" do
    test "returns true for equivalent uuids" do
      uuid = Ecto.ShortUUID.autogenerate()
      assert Ecto.ShortUUID.equal?(uuid, uuid)
    end

    test "returns false for different uuids" do
      uuid1 = Ecto.ShortUUID.autogenerate()
      uuid2 = Ecto.ShortUUID.autogenerate()

      refute Ecto.ShortUUID.equal?(uuid1, uuid2)
    end

    test "returns false for non-UUID inputs" do
      assert false === Ecto.ShortUUID.equal?(1, "1")
    end
  end

  describe "generate/0" do
    test "generates valid shortuuids" do
      for _ <- 1..10 do
        assert {:ok, _shortuuid} = Ecto.ShortUUID.generate() |> Ecto.ShortUUID.cast()
      end
    end
  end

  describe "autogenerate/0" do
    test "autogenerates valid shortuuids" do
      for _ <- 1..10 do
        assert <<_::176>> = Ecto.ShortUUID.autogenerate()
      end
    end
  end

  describe "type/0" do
    test "returns :uuid" do
      assert :uuid === Ecto.ShortUUID.type()
    end
  end
end
