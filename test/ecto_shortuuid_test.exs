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

  describe "edge cases" do
    test "handles malformed shortuuids correctly" do
      # Too short shortuuid
      assert :error == Ecto.ShortUUID.cast("9VprZJ")

      # Shortuuid with invalid characters
      assert :error == Ecto.ShortUUID.cast("9VprZJ9U7T/g2PJ8BfTAek")

      # Empty string
      assert :error == Ecto.ShortUUID.cast("")
    end

    test "handles specific nil values" do
      assert :error == Ecto.ShortUUID.cast(nil)
      assert :error == Ecto.ShortUUID.load(nil)
      assert :error == Ecto.ShortUUID.dump(nil)
    end

    test "supports different UUID versions" do
      # UUID v1 (time-based)
      uuid_v1 = "c9aec822-6d99-11ee-b962-0242ac120002"
      assert {:ok, _} = Ecto.ShortUUID.cast(uuid_v1)

      # UUID v4 (random)
      uuid_v4 = "b44f3c49-0403-4dcd-bd5f-e22ea6d48a4f"
      assert {:ok, _} = Ecto.ShortUUID.cast(uuid_v4)

      # Both should result in valid shortuuids
      {:ok, shortuuid_v1} = Ecto.ShortUUID.cast(uuid_v1)
      {:ok, shortuuid_v4} = Ecto.ShortUUID.cast(uuid_v4)

      assert {:ok, _} = Ecto.ShortUUID.dump(shortuuid_v1)
      assert {:ok, _} = Ecto.ShortUUID.dump(shortuuid_v4)
    end

    test "handles incomplete UUID formats" do
      # Missing sections
      assert :error == Ecto.ShortUUID.cast("c9aec822-6d99-11ee-b962")

      # Too many sections
      assert :error == Ecto.ShortUUID.cast("c9aec822-6d99-11ee-b962-0242ac120002-extra")

      # Wrong delimiters
      assert :error == Ecto.ShortUUID.cast("c9aec822_6d99_11ee_b962_0242ac120002")
    end
  end

  describe "round trip conversions" do
    test "standard UUID can be converted to ShortUUID and back" do
      # Start with a standard UUID
      original_uuid = "2a162ee5-02f4-4701-9e87-72762cbce5e2"

      # Convert to ShortUUID
      {:ok, short_uuid} = Ecto.ShortUUID.cast(original_uuid)

      # Convert back to binary and then to standard UUID
      {:ok, binary_uuid} = Ecto.ShortUUID.dump(short_uuid)
      {:ok, converted_uuid} = Ecto.UUID.load(binary_uuid)

      # Should get the original UUID back
      assert original_uuid == converted_uuid
    end

    test "generated ShortUUID can be dumped and loaded" do
      # Generate a new ShortUUID
      short_uuid = Ecto.ShortUUID.autogenerate()

      # Dump to binary and load back
      {:ok, binary_uuid} = Ecto.ShortUUID.dump(short_uuid)
      {:ok, loaded_short_uuid} = Ecto.ShortUUID.load(binary_uuid)

      # Should get back the same ShortUUID
      assert short_uuid == loaded_short_uuid
    end
  end

  describe "boundary cases" do
    test "handles all zeros UUID" do
      all_zeros_uuid = "00000000-0000-0000-0000-000000000000"
      {:ok, short_uuid} = Ecto.ShortUUID.cast(all_zeros_uuid)

      # Should be able to dump and decode correctly
      {:ok, binary} = Ecto.ShortUUID.dump(short_uuid)
      assert <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>> == binary
    end

    test "handles all ones UUID" do
      all_ones_uuid = "ffffffff-ffff-ffff-ffff-ffffffffffff"
      {:ok, short_uuid} = Ecto.ShortUUID.cast(all_ones_uuid)

      # Should be able to dump and decode correctly
      {:ok, binary} = Ecto.ShortUUID.dump(short_uuid)

      assert <<255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255>> ==
               binary
    end
  end

  describe "compatibility with Ecto.UUID" do
    test "ShortUUID.dump/1 produces the same binary as UUID.dump/1" do
      # Start with standard UUID
      uuid_string = "2a162ee5-02f4-4701-9e87-72762cbce5e2"

      # Dump via both methods
      {:ok, binary_from_shortuuid} = Ecto.ShortUUID.dump(uuid_string)
      {:ok, binary_from_uuid} = Ecto.UUID.dump(uuid_string)

      # Both should produce identical binary representation
      assert binary_from_shortuuid == binary_from_uuid
    end

    test "ShortUUID.cast/1 and load/1 work with various UUID formats" do
      # Mixed case UUID should be accepted
      mixed_case_uuid = "2A162ee5-02F4-4701-9e87-72762cBcE5e2"
      assert {:ok, _} = Ecto.ShortUUID.cast(mixed_case_uuid)

      # Binary from mixed case UUID should load correctly
      {:ok, binary} = Ecto.UUID.dump(mixed_case_uuid)
      assert {:ok, _} = Ecto.ShortUUID.load(binary)
    end
  end

  describe "error handling" do
    test "cast/1 with invalid ShortUUID format" do
      # Too long ShortUUID
      assert :error = Ecto.ShortUUID.cast(@test_shortuuid <> "extra")

      # ShortUUID with special chars that shouldn't be in alphabet
      assert :error = Ecto.ShortUUID.cast("Invalid$ShortUUID")
    end

    test "load/1 with binary that looks like UUID but has wrong size" do
      # 15-byte binary instead of 16
      assert :error = Ecto.ShortUUID.load(<<0::120>>)

      # 17-byte binary instead of 16
      assert :error = Ecto.ShortUUID.load(<<0::136>>)
    end
  end
end
