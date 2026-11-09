defmodule Ecto.ShortUUID.DecoderTest do
  use ExUnit.Case, async: true

  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"

  # Decodes anything prefixed with "x" to the remainder, whether or not that
  # remainder is a valid UUID.
  defmodule LaxEncoder do
    def encode(uuid), do: {:ok, "x" <> uuid}
    def decode("x" <> rest), do: {:ok, rest}
    def decode(_), do: {:error, "invalid"}
  end

  # Like the README example: no catch-all decode/1 clause.
  defmodule PartialEncoder do
    def encode(uuid), do: {:ok, "custom-" <> uuid}
    def decode("custom-" <> uuid), do: {:ok, uuid}
  end

  # decode/1 itself matches, but crashes further down.
  defmodule CrashingEncoder do
    def encode(uuid), do: {:ok, uuid}
    def decode(shortuuid), do: {:ok, lookup(shortuuid)}
    defp lookup("known"), do: "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  end

  # A decoder that never reports an error must not cause compile warnings
  # in the generated type.
  defmodule InfallibleDecoder do
    def encode(uuid), do: {:ok, uuid}
    def decode(shortuuid), do: {:ok, shortuuid}
  end

  for {name, encoder} <- [
        LaxType: LaxEncoder,
        PartialType: PartialEncoder,
        CrashingType: CrashingEncoder,
        InfallibleType: InfallibleDecoder
      ] do
    defmodule Module.concat(__MODULE__, name) do
      use Ecto.ShortUUID.Builder, encoder: encoder
    end
  end

  alias __MODULE__.{CrashingType, InfallibleType, LaxType, PartialType}

  describe "cast/1 with a decoder returning non-UUIDs" do
    test "accepts strings that decode to a valid UUID" do
      assert {:ok, "x" <> @test_uuid} == LaxType.cast("x" <> @test_uuid)
    end

    test "rejects strings that decode to something other than a UUID" do
      assert :error == LaxType.cast("xnot-a-uuid")
      assert :error == LaxType.cast("x")
      assert :error == LaxType.dump("xnot-a-uuid")
    end
  end

  describe "round trip" do
    test "cast/1 rejects strings that don't encode back to themselves" do
      # LaxEncoder decodes "x" <> uppercase UUID, but encodes to lowercase.
      upper = "x" <> String.upcase(@test_uuid)
      assert :error == LaxType.cast(upper)
      assert {:ok, "x" <> @test_uuid} == LaxType.cast(@test_uuid)
    end

    test "dump/1 accepts anything that decodes to a valid UUID" do
      upper = "x" <> String.upcase(@test_uuid)
      assert Ecto.UUID.dump(@test_uuid) == LaxType.dump(upper)
    end
  end

  describe "default ShortUUID encoder" do
    test "rejects strings that aren't 22 characters long" do
      # shortuuid 2.x decodes these by padding them; 3.x and 4.x reject them.
      for input <- ["", "9VprZJ", "2", "9VprZJ9U7Tgg2PJ8BfTAe", "9VprZJ9U7Tgg2PJ8BfTAek2"] do
        assert :error == Ecto.ShortUUID.cast(input), "cast(#{inspect(input)})"
        assert :error == Ecto.ShortUUID.dump(input), "dump(#{inspect(input)})"
      end
    end

    test "accepts what the encoder produces" do
      for _ <- 1..50 do
        uuid = Ecto.UUID.generate()
        {:ok, shortuuid} = ShortUUID.encode(uuid)
        assert {:ok, shortuuid} == Ecto.ShortUUID.cast(shortuuid)
        assert Ecto.UUID.dump(uuid) == Ecto.ShortUUID.dump(shortuuid)
      end
    end
  end

  describe "custom encoders" do
    test "are not restricted to 22 characters" do
      assert {:ok, "x" <> @test_uuid} == LaxType.cast("x" <> @test_uuid)
      assert {:ok, _} = LaxType.dump("x" <> @test_uuid)
      assert {:ok, "x" <> @test_uuid} == LaxType.cast(@test_uuid)
    end
  end

  describe "decoder without a catch-all clause" do
    test "cast/1 and dump/1 return :error instead of raising" do
      assert :error == PartialType.cast("garbage")
      assert :error == PartialType.dump("garbage")
    end

    test "valid input still works" do
      assert {:ok, "custom-" <> @test_uuid} == PartialType.cast(@test_uuid)
      assert {:ok, "custom-" <> @test_uuid} == PartialType.cast("custom-" <> @test_uuid)
      assert Ecto.UUID.dump(@test_uuid) == PartialType.dump("custom-" <> @test_uuid)
    end
  end

  describe "decoder crashing for other reasons" do
    test "the error is not swallowed" do
      assert_raise FunctionClauseError, fn -> CrashingType.cast("ok") end
      assert_raise FunctionClauseError, fn -> CrashingType.dump("ok") end
    end
  end

  describe "decoder that never fails" do
    test "only accepts input that is a valid UUID" do
      assert {:ok, @test_uuid} == InfallibleType.cast(@test_uuid)
      assert :error == InfallibleType.cast("garbage")
    end
  end

  describe "cast/1 and dump/1 consistency" do
    # dump/1 may accept more than cast/1 (non-canonical spellings), but
    # everything cast/1 accepts must dump, to the same UUID as its cast.
    @inputs [
      @test_uuid,
      "9VprZJ9U7Tgg2PJ8BfTAek",
      "x" <> @test_uuid,
      "xnot-a-uuid",
      "custom-" <> @test_uuid,
      "custom-garbage",
      "9VprZJ",
      "",
      "garbage",
      <<0::128>>,
      nil,
      1
    ]

    for type <- [Ecto.ShortUUID, LaxType, PartialType, InfallibleType] do
      test "#{inspect(type)} can dump every value it casts" do
        type = unquote(type)

        for input <- @inputs, {:ok, casted} <- [type.cast(input)] do
          assert {:ok, binary} = type.dump(input),
                 "#{inspect(type)}: casts but doesn't dump #{inspect(input)}"

          assert type.dump(casted) == {:ok, binary}
        end
      end
    end
  end
end
