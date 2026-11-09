defmodule Ecto.ShortUUID.EncoderErrorsTest do
  use ExUnit.Case, async: true

  # An encoder that can decode but never encode successfully.
  defmodule FailingEncoder do
    def encode(_uuid), do: {:error, "encoding failed"}
    def decode(shortuuid), do: ShortUUID.decode(shortuuid)
  end

  # An encoder that returns something outside of the `{:ok, _} | {:error, _}` contract.
  defmodule BadReturnEncoder do
    def encode(_uuid), do: :oops
    def decode(shortuuid), do: ShortUUID.decode(shortuuid)
  end

  # An encoder whose encode/1 can never fail. Compiling a type for it must not
  # produce warnings (e.g. from the type checker) for the error branches.
  defmodule InfallibleEncoder do
    def encode(uuid), do: {:ok, "x" <> uuid}
    def decode("x" <> uuid), do: {:ok, uuid}
    def decode(_), do: {:error, "invalid"}
  end

  defmodule FailingType do
    use Ecto.ShortUUID.Builder, encoder: FailingEncoder
  end

  defmodule BadReturnType do
    use Ecto.ShortUUID.Builder, encoder: BadReturnEncoder
  end

  defmodule InfallibleType do
    use Ecto.ShortUUID.Builder, encoder: InfallibleEncoder
  end

  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @test_uuid_binary <<0x2A, 0x16, 0x2E, 0xE5, 0x02, 0xF4, 0x47, 0x01, 0x9E, 0x87, 0x72, 0x76,
                      0x2C, 0xBC, 0xE5, 0xE2>>

  for type <- [FailingType, BadReturnType] do
    describe "#{inspect(type)}" do
      test "cast/1 returns :error when the encoder fails" do
        assert :error === unquote(type).cast(@test_uuid)
      end

      test "load/1 returns :error when the encoder fails" do
        assert :error === unquote(type).load(@test_uuid_binary)
      end

      test "generate/0 raises instead of returning the error" do
        assert_raise RuntimeError, ~r/encode\/1 failed to encode generated UUID/, fn ->
          unquote(type).generate()
        end
      end

      test "autogenerate/0 raises instead of returning the error" do
        assert_raise RuntimeError, ~r/encode\/1 failed to encode generated UUID/, fn ->
          unquote(type).autogenerate()
        end
      end

      test "Ecto.Changeset.cast/4 reports the field as invalid" do
        changeset =
          Ecto.Changeset.cast({%{}, %{id: unquote(type)}}, %{"id" => @test_uuid}, [:id])

        refute changeset.valid?
        assert {"is invalid", _} = changeset.errors[:id]
      end
    end
  end

  describe "InfallibleType" do
    test "works with an encoder that never fails" do
      assert {:ok, "x" <> @test_uuid} == InfallibleType.cast(@test_uuid)
      assert {:ok, "x" <> @test_uuid} == InfallibleType.load(@test_uuid_binary)
      assert "x" <> _ = InfallibleType.generate()
    end
  end
end
