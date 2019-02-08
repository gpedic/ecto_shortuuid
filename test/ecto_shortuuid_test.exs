defmodule Ecto.ShortUUIDTest do
  use ExUnit.Case, async: true
  doctest Ecto.ShortUUID

  @test_shortuuid "keATfB8JP2ggT7U9JZrpV9"
  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @test_uuid_binary <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76,
                      0x2C, 0xBC, 0xE5, 0xE2>>

  describe "cast/1" do

    test "can cast shortuuids" do
      assert {:ok, @test_shortuuid} = Ecto.ShortUUID.cast(@test_shortuuid)
    end

    test "can cast UUIDs" do
      assert {:ok, @test_shortuuid} = Ecto.ShortUUID.cast(@test_uuid)
    end

    test "can't cast invalid UUIDs" do
      assert :error === Ecto.ShortUUID.cast("")
      assert :error === Ecto.ShortUUID.cast("invalid")
      assert :error === Ecto.ShortUUID.cast(nil)
      assert :error === Ecto.ShortUUID.cast(0)
      assert :error === Ecto.ShortUUID.cast(1)
      assert :error === Ecto.ShortUUID.load(<<0>>)
      assert :error === Ecto.ShortUUID.cast(false)
      assert :error === Ecto.ShortUUID.cast(true)
    end
  end

  describe "load/1" do

    test "loads binary UUID" do
      assert {:ok, @test_shortuuid} = Ecto.ShortUUID.load(@test_uuid_binary)
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
      assert :error === Ecto.ShortUUID.load(<< 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
    end

    test "fails if binary < 128bit" do
      assert :error === Ecto.ShortUUID.load(<< 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>)
    end
  end

  describe "dump/1" do
    test "can dump shortuuid" do
      assert {:ok, @test_uuid_binary} = Ecto.ShortUUID.dump(@test_shortuuid)
    end

    test "can dump UUID" do
      assert {:ok, @test_uuid_binary} = Ecto.ShortUUID.dump(@test_uuid)
    end

    test "fails to dump binary" do
      assert :error === Ecto.ShortUUID.dump(@test_uuid_binary)
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

  test "autogenerate/0" do
    assert <<_::176>> = Ecto.ShortUUID.autogenerate()
  end
end
