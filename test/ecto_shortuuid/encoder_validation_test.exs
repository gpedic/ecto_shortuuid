defmodule Ecto.ShortUUID.EncoderValidationTest do
  use ExUnit.Case, async: true

  defmodule NoDecode do
    def encode(uuid), do: {:ok, uuid}
  end

  defmodule NoEncodeNoDecode do
  end

  defp compile(code), do: Code.compile_string(code, "encoder_validation_test")

  test "missing :encoder option" do
    assert_raise ArgumentError, ~r/requires an :encoder option/, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.MissingOption do
        use Ecto.ShortUUID.Builder
      end
      """)
    end
  end

  test "encoder that is not a module" do
    assert_raise ArgumentError, ~r/must be a module, got: "ShortUUID"/, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.NotAModule do
        use Ecto.ShortUUID.Builder, encoder: "ShortUUID"
      end
      """)
    end
  end

  test "encoder module that does not exist" do
    message =
      ~r/DoesNotExist, could not be compiled or loaded \(reason: .+\)\. If it is defined further down in the same file, move it above the type or into its own file$/

    assert_raise ArgumentError, message, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.UnknownEncoder do
        use Ecto.ShortUUID.Builder, encoder: DoesNotExist
      end
      """)
    end
  end

  test "encoder module without decode/1" do
    assert_raise ArgumentError, ~r/NoDecode, does not export decode\/1$/, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.MissingDecode do
        use Ecto.ShortUUID.Builder, encoder: Ecto.ShortUUID.EncoderValidationTest.NoDecode
      end
      """)
    end
  end

  test "encoder module without encode/1 and decode/1" do
    assert_raise ArgumentError, ~r/does not export encode\/1 and decode\/1/, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.MissingBoth do
        use Ecto.ShortUUID.Builder, encoder: Ecto.ShortUUID.EncoderValidationTest.NoEncodeNoDecode
      end
      """)
    end
  end

  test "encoder nested in the type module, referenced by its full name" do
    {module, _} =
      """
      defmodule Ecto.ShortUUID.EncoderValidationTest.NestedFullName do
        defmodule Enc do
          defdelegate encode(uuid), to: ShortUUID
          defdelegate decode(shortuuid), to: ShortUUID
        end

        use Ecto.ShortUUID.Builder, encoder: Ecto.ShortUUID.EncoderValidationTest.NestedFullName.Enc
      end
      """
      |> compile()
      |> List.keyfind(Ecto.ShortUUID.EncoderValidationTest.NestedFullName, 0)

    assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} ==
             module.cast("2a162ee5-02f4-4701-9e87-72762cbce5e2")
  end

  test "encoder nested in the type module, referenced through __MODULE__" do
    {module, _} =
      """
      defmodule Ecto.ShortUUID.EncoderValidationTest.NestedModuleAlias do
        defmodule Enc do
          defdelegate encode(uuid), to: ShortUUID
          defdelegate decode(shortuuid), to: ShortUUID
        end

        use Ecto.ShortUUID.Builder, encoder: __MODULE__.Enc
      end
      """
      |> compile()
      |> List.keyfind(Ecto.ShortUUID.EncoderValidationTest.NestedModuleAlias, 0)

    assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} ==
             module.cast("2a162ee5-02f4-4701-9e87-72762cbce5e2")
  end

  test "nested encoder without decode/1" do
    assert_raise ArgumentError, ~r/NestedMissingDecode.Enc, does not export decode\/1$/, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.NestedMissingDecode do
        defmodule Enc do
          def encode(uuid), do: {:ok, uuid}
        end

        use Ecto.ShortUUID.Builder, encoder: __MODULE__.Enc
      end
      """)
    end
  end

  test "encoder given through an alias" do
    [{module, _}] =
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.Aliased do
        alias ShortUUID, as: MyEncoder
        use Ecto.ShortUUID.Builder, encoder: MyEncoder
      end
      """)

    assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} ==
             module.cast("2a162ee5-02f4-4701-9e87-72762cbce5e2")
  end
end
