defmodule Ecto.ShortUUID.BuilderTest do
  use ExUnit.Case, async: true

  # Mock implementation of ShortUUID with custom format
  defmodule MockShortUUID do
    # Handle binary UUIDs
    @behaviour ShortUUID.Behaviour
    def encode(<<_::128>> = uuid) do
      # Simply prefix the hex string with "mock-"
      {:ok, "mock-" <> Base.encode16(uuid, case: :lower)}
    end

    # Handle string UUIDs by first converting them to binary
    def encode(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid) do
      case Ecto.UUID.dump(uuid) do
        {:ok, binary} -> encode(binary)
        :error -> {:error, "Invalid UUID string"}
      end
    end

    # Reject other formats
    def encode(_) do
      {:error, "Invalid UUID format"}
    end

    def encode!(<<_::128>> = uuid) do
      "mock-" <> Base.encode16(uuid, case: :lower)
    end

    def encode!(uuid) do
      case encode(uuid) do
        {:ok, encoded} -> encoded
        {:error, reason} -> raise ArgumentError, message: reason
      end
    end

    # Update decode to return string UUIDs instead of binary UUIDs
    def decode("mock-" <> hex) do
      case Base.decode16(hex, case: :mixed) do
        {:ok, binary} when byte_size(binary) == 16 ->
          # Convert binary UUID to string format
          Ecto.UUID.load(binary)
        _ ->
          {:error, "Invalid mock uuid format"}
      end
    end

    def decode(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid) do
      # Return the string UUID as is
      {:ok, uuid}
    end

    def decode(_) do
      {:error, "Not a valid uuid format"}
    end

    def decode!(shortuuid) do
      case decode(shortuuid) do
        {:ok, uuid_string} -> uuid_string
        {:error, reason} -> raise ArgumentError, message: reason
      end
    end
  end

  # Custom ShortUUID type using builder
  defmodule CustomShortUUID do
    use Ecto.ShortUUID.Builder, module: MockShortUUID
  end

  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @test_uuid_binary <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76,
                      0x2C, 0xBC, 0xE5, 0xE2>>
  @test_mock_shortuuid "mock-2a162ee502f447019e8772762cbce5e2"

  describe "CustomShortUUID.type/0" do
    test "returns :uuid" do
      assert :uuid == CustomShortUUID.type()
    end
  end

  describe "CustomShortUUID.cast/1" do
    test "casts standard UUID to custom format" do
      assert {:ok, @test_mock_shortuuid} == CustomShortUUID.cast(@test_uuid)
    end

    test "accepts already encoded custom shortuuid" do
      assert {:ok, @test_mock_shortuuid} == CustomShortUUID.cast(@test_mock_shortuuid)
    end

    test "rejects invalid custom shortuuids" do
      assert :error == CustomShortUUID.cast("mock-invalid")
      assert :error == CustomShortUUID.cast("not-a-mock-uuid")
    end

    test "rejects binary UUIDs" do
      assert :error == CustomShortUUID.cast(@test_uuid_binary)
    end
  end

  describe "CustomShortUUID.load/1" do
    test "loads binary UUID to custom shortuuid format" do
      assert {:ok, @test_mock_shortuuid} == CustomShortUUID.load(@test_uuid_binary)
    end

    test "raises for string UUID" do
      assert_raise ArgumentError, fn ->
        CustomShortUUID.load(@test_uuid)
      end
    end

    test "returns error for invalid binary" do
      assert :error == CustomShortUUID.load(<<1, 2, 3>>)
      assert :error == CustomShortUUID.load(nil)
    end
  end

  describe "CustomShortUUID.dump/1" do
    test "dumps custom shortuuid to binary" do
      assert {:ok, @test_uuid_binary} == CustomShortUUID.dump(@test_mock_shortuuid)
    end

    test "dumps standard UUID to binary" do
      assert {:ok, @test_uuid_binary} == CustomShortUUID.dump(@test_uuid)
    end

    test "returns error for invalid format" do
      assert :error == CustomShortUUID.dump("invalid")
      assert :error == CustomShortUUID.dump("mock-invalid")
    end
  end

  describe "CustomShortUUID.generate/0" do
    test "generates valid custom shortuuids" do
      for _ <- 1..5 do
        generated = CustomShortUUID.generate()
        assert String.starts_with?(generated, "mock-")
        assert {:ok, _} = CustomShortUUID.cast(generated)
      end
    end
  end

  describe "CustomShortUUID.autogenerate/0" do
    test "returns a valid custom shortuuid" do
      assert String.starts_with?(CustomShortUUID.autogenerate(), "mock-")
    end
  end

  describe "compatibility between types" do
    test "both types can handle the same standard UUID" do
      # Start with a standard UUID string
      standard_uuid = @test_uuid

      # Dump using both types - should produce the same binary
      {:ok, binary1} = CustomShortUUID.dump(standard_uuid)
      {:ok, binary2} = Ecto.ShortUUID.dump(standard_uuid)

      assert binary1 == binary2
    end
  end
end
