defmodule Ecto.ShortUUIDTest do
  use ExUnit.Case, async: true
  doctest Ecto.ShortUUID

  @test_shortuuid "keATfB8JP2ggT7U9JZrpV9"
  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @test_uuid_binary <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76,
                      0x2C, 0xBC, 0xE5, 0xE2>>

  test "cast" do
    assert Ecto.ShortUUID.cast(@test_shortuuid) == {:ok, @test_shortuuid}
    assert Ecto.ShortUUID.cast(@test_uuid) == {:ok, @test_shortuuid}
    assert Ecto.ShortUUID.cast("invalid") == :error
  end

  test "load" do
    assert Ecto.ShortUUID.load(@test_uuid_binary) == {:ok, @test_shortuuid}
    assert Ecto.UUID.load("") == :error
  end

  test "dump" do
    assert Ecto.ShortUUID.dump(@test_shortuuid) == {:ok, @test_uuid_binary}
    assert Ecto.ShortUUID.dump(@test_uuid) == {:ok, @test_uuid_binary}
    assert Ecto.ShortUUID.dump(@test_uuid_binary) == :error
  end
end
