defmodule Ecto.ShortUUID.Builder do
  @moduledoc """
  A builder module for creating Ecto types that use custom ShortUUID implementations.

  ## Example

      defmodule MyBase58UUID do
        use ShortUUID.Builder, alphabet: :base58
      end

      defmodule MyShortUUID do
        use Ecto.ShortUUID.Builder, encoder: MyBase58UUID
      end

  The specified encoder must be a [ShortUUID](https://github.com/gpedic/ex_shortuuid) compatible module.
  """

  defmacro __using__(opts) do
    encoder = Keyword.fetch!(opts, :encoder)

    quote do
      @behaviour Ecto.Type
      alias Ecto.UUID

      @encoder unquote(encoder)

      @typedoc """
      A hex-encoded UUID string.
      """
      @type uuid :: <<_::288>>

      @typedoc """
      A ShortUUID string.
      """
      @type shortuuid :: binary

      @typedoc """
      A raw binary representation of a UUID.
      """
      @type raw :: <<_::128>>

      @doc """
      Returns the underlying schema type for the custom type.

      For ShortUUID, this is always `:uuid` as the data is stored in UUID format
      in the database.
      """
      @impl true
      @spec type() :: :uuid
      def type, do: :uuid

      @doc """
      Casts a value to a ShortUUID.

      Accepts:
      - Standard UUID strings (converts them to ShortUUID format)
      - ShortUUID strings (validates them)

      Returns:
      - `{:ok, shortuuid}` on success
      - `:error` on failure
      """
      @impl true
      @spec cast(uuid() | shortuuid() | any()) :: {:ok, shortuuid()} | :error
      def cast(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid) do
        case UUID.cast(uuid) do
          :error -> :error
          {:ok, casted} -> @encoder.encode(casted)
        end
      end

      def cast(shortuuid) when is_binary(shortuuid) do
        case @encoder.decode(shortuuid) do
          {:ok, _} -> {:ok, shortuuid}
          {:error, _} -> :error
        end
      end

      def cast(_), do: :error

      @doc """
      Loads a binary UUID from the database and converts it to ShortUUID format.

      Returns:
      - `{:ok, shortuuid}` on success
      - `:error` on failure

      Raises an `ArgumentError` if given a string UUID instead of binary.
      """
      @impl true
      @spec load(raw() | any()) :: {:ok, shortuuid()} | :error
      def load(uuid) do
        case UUID.load(uuid) do
          {:ok, uuid} -> @encoder.encode(uuid)
          _ -> :error
        end
      end

      @doc """
      Dumps a ShortUUID or standard UUID to binary format for database storage.

      Accepts:
      - ShortUUID strings
      - Standard UUID strings

      Returns:
      - `{:ok, binary_uuid}` on success
      - `:error` on failure
      """
      @impl true
      @spec dump(shortuuid() | uuid() | any()) :: {:ok, raw()} | :error
      def dump(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid), do: UUID.dump(uuid)

      def dump(shortuuid) when is_binary(shortuuid) do
        with {:ok, uuid} <- @encoder.decode(shortuuid),
             {:ok, binary_uuid} <- UUID.dump(uuid) do
          {:ok, binary_uuid}
        else
          _ -> :error
        end
      end

      def dump(_), do: :error

      @doc """
      Ecto v3 callback
      Dictates how the type should be treated inside embeds.
      https://hexdocs.pm/ecto/Ecto.Type.html#c:embed_as/1
      """
      @impl true
      @spec embed_as(term()) :: :self
      def embed_as(_), do: :self

      @doc """
      Ecto v3 callback
      Checks if two terms are semantically equal.
      https://hexdocs.pm/ecto/Ecto.Type.html#c:equal?/2
      """
      @impl true
      @spec equal?(term(), term()) :: boolean()
      def equal?(term1, term2), do: term1 == term2

      @doc """
      Generates a ShortUUID string based on a version 4 (random) UUID.
      """
      @spec generate() :: shortuuid()
      def generate do
        UUID.generate()
        |> @encoder.encode()
        |> elem(1)
      end

      @doc """
      Generates a random ShortUUID string for use in primary keys.

      This is called by Ecto when a record is inserted if the schema has
      `@primary_key {:id, CustomShortUUIDType, autogenerate: true}`.
      """
      @impl true
      @spec autogenerate() :: shortuuid()
      def autogenerate do
        generate()
      end
    end
  end
end
