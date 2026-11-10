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

  test "encoder given as nil" do
    assert_raise ArgumentError, ~r/must be a module, got: nil/, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.NilEncoder do
        use Ecto.ShortUUID.Builder, encoder: nil
      end
      """)
    end
  end

  test "unknown options" do
    message = ~r/unknown options given to use Ecto.ShortUUID.Builder: \[:encodr\]/

    assert_raise ArgumentError, message, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.UnknownOption do
        use Ecto.ShortUUID.Builder, encoder: ShortUUID, encodr: ShortUUID
      end
      """)
    end
  end

  test "options that are not a keyword list" do
    assert_raise ArgumentError, ~r/expects a keyword list of options, got: ShortUUID/, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.NotAKeywordList do
        use Ecto.ShortUUID.Builder, ShortUUID
      end
      """)
    end
  end

  test "encoder given as a variable or attribute is validated too" do
    assert_raise ArgumentError, ~r/DoesNotExist, could not be compiled or loaded/, fn ->
      compile("""
      encoder = DoesNotExist

      defmodule Ecto.ShortUUID.EncoderValidationTest.UnknownVariableEncoder do
        use Ecto.ShortUUID.Builder, encoder: encoder
      end
      """)
    end

    assert_raise ArgumentError, ~r/NoDecode, does not export decode\/1$/, fn ->
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.AttributeMissingDecode do
        @enc Ecto.ShortUUID.EncoderValidationTest.NoDecode
        use Ecto.ShortUUID.Builder, encoder: @enc
      end
      """)
    end

    assert_raise ArgumentError, ~r/must be a module, got: "ShortUUID"/, fn ->
      compile("""
      encoder = "ShortUUID"

      defmodule Ecto.ShortUUID.EncoderValidationTest.StringVariableEncoder do
        use Ecto.ShortUUID.Builder, encoder: encoder
      end
      """)
    end
  end

  test "the type module can define its own @encoder attribute" do
    [{module, _}] =
      compile("""
      defmodule Ecto.ShortUUID.EncoderValidationTest.OwnEncoderAttribute do
        use Ecto.ShortUUID.Builder, encoder: ShortUUID

        @encoder DoesNotExist
        def encoder, do: @encoder
      end
      """)

    assert DoesNotExist == module.encoder()

    assert {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"} ==
             module.cast("2a162ee5-02f4-4701-9e87-72762cbce5e2")
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
