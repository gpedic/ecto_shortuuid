defmodule Ecto.ShortUUID.CustomAlphabetTest do
  use ExUnit.Case, async: true

  defmodule Base58 do
    use ShortUUID.Builder, alphabet: :base58
  end

  defmodule Base58Type do
    use Ecto.ShortUUID.Builder, encoder: Base58
  end

  defmodule Base62 do
    use ShortUUID.Builder, alphabet: :base62
  end

  defmodule Base62Type do
    use Ecto.ShortUUID.Builder, encoder: Base62
  end

  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @test_uuid_binary <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76,
                      0x2C, 0xBC, 0xE5, 0xE2>>

  test "base58 type encodes with the base58 alphabet" do
    type = Base58Type
    short = "6CRqjx8HiL65itHBngudWH"

    assert {:ok, short} === type.cast(@test_uuid)
    assert {:ok, short} === type.cast(String.upcase(@test_uuid))
    assert {:ok, short} === type.cast(short)
    assert {:ok, @test_uuid_binary} === type.dump(short)
    assert {:ok, short} === type.load(@test_uuid_binary)
    assert Ecto.UUID.dump(@test_uuid) === type.dump(short)
  end

  test "invalid UTF-8 is rejected instead of raising" do
    # shortuuid < 4.2 raised ArgumentError for these. Padded to 22 bytes so
    # the default ShortUUID length check doesn't short-circuit them.
    inputs =
      for prefix <- ["😀" <> <<0xFF>>, <<0xFF, 0xFE>>, "abc" <> <<0x80>>] do
        prefix <> String.duplicate("a", 22 - byte_size(prefix))
      end

    for type <- [Ecto.ShortUUID, Base58Type, Base62Type], input <- inputs do
      assert type.cast(input) == :error
      assert type.dump(input) == :error
    end
  end

  for type <- [Base58Type, Base62Type] do
    test "#{inspect(type)} round trips random UUIDs" do
      type = unquote(type)

      for _ <- 1..50 do
        uuid = Ecto.UUID.generate()
        {:ok, short} = type.cast(uuid)

        refute short == uuid
        assert {:ok, short} === type.cast(short)
        assert Ecto.UUID.dump(uuid) === type.dump(short)
        assert Ecto.UUID.dump(uuid) === type.dump(uuid)

        {:ok, binary} = type.dump(short)
        assert {:ok, short} === type.load(binary)
      end

      generated = type.generate()
      assert {:ok, ^generated} = type.cast(generated)
    end

    test "#{inspect(type)} rejects invalid input" do
      type = unquote(type)

      assert :error === type.cast("")
      assert :error === type.cast("not a valid id!")
      assert :error === type.cast(String.duplicate("z", 22))
      assert :error === type.dump(String.duplicate("z", 22))
      assert :error === type.cast(@test_uuid_binary)
      assert :error === type.load("nope")
    end
  end
end
