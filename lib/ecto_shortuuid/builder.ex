defmodule Ecto.ShortUUID.Builder do
  @moduledoc """
  A builder module for creating Ecto types that use custom ShortUUID implementations.

  ## Example

      defmodule MyBase58UUID do
        use ShortUUID.Builder, alphabet: :base58
      end

      defmodule MyShortUUID do
        use Ecto.ShortUUID.Builder, module: MyBase58UUID
      end

  The specified module must implement the ShortUUID interface with `encode/1`, `encode!/1`, and `decode/1`.
  """

  defmacro __using__(opts) do
    shortuuid_module = Keyword.fetch!(opts, :module)

    quote do
      @behaviour Ecto.Type
      alias Ecto.UUID

      @shortuuid_module unquote(shortuuid_module)

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
          {:ok, casted} -> @shortuuid_module.encode(casted)
        end
      end

      def cast(shortuuid) when is_binary(shortuuid) do
        case @shortuuid_module.decode(shortuuid) do
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
          {:ok, uuid} -> @shortuuid_module.encode(uuid)
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
        with {:ok, uuid} <- @shortuuid_module.decode(shortuuid),
             {:ok, binary_uuid} <- UUID.dump(uuid) do
          {:ok, binary_uuid}
        else
          _ -> :error
        end
      end

      def dump(_), do: :error

      @doc """
      Determines how the type is embedded in a changeset.
      """
      @impl true
      @spec embed_as(term()) :: :self
      def embed_as(_), do: :self

      @doc """
      Checks if two terms are equal.
      """
      @impl true
      @spec equal?(term(), term()) :: boolean()
      def equal?(term1, term2), do: term1 == term2

      @doc """
      Generates a random ShortUUID string.
      """
      @spec generate() :: shortuuid()
      def generate do
        UUID.generate()
        |> @shortuuid_module.encode()
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
