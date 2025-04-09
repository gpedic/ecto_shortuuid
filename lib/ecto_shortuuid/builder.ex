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

      @impl true
      def type, do: :uuid

      @impl true
      def cast(<<_::288>> = uuid) do
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

      @impl true
      def load(uuid) do
        case UUID.load(uuid) do
          {:ok, uuid} -> @shortuuid_module.encode(uuid)
          _ -> :error
        end
      end

      @impl true
      def dump(<<_::288>> = uuid), do: UUID.dump(uuid)

      def dump(shortuuid) when is_binary(shortuuid) do
        with {:ok, uuid} <- @shortuuid_module.decode(shortuuid),
             {:ok, binary_uuid} <- UUID.dump(uuid) do
          {:ok, binary_uuid}
        else
          _ -> :error
        end
      end

      def dump(_), do: :error

      @impl true
      def embed_as(_), do: :self

      @impl true
      def equal?(term1, term2), do: term1 == term2

      def generate do
        UUID.generate()
        |> @shortuuid_module.encode()
        |> elem(1)
      end

      @impl true
      def autogenerate do
        generate()
      end
    end
  end
end
