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

  `cast/1` and `dump/1` only accept a ShortUUID string if `encoder.decode/1`
  returns `{:ok, uuid}` with a valid UUID and `encoder.encode/1` turns that
  UUID back into the same string. Every accepted ShortUUID is therefore the
  canonical encoding of its UUID: input the decoder merely tolerates (e.g.
  truncated strings or a different letter case) is rejected.
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
      - ShortUUID strings, if the encoder decodes them to a valid UUID and
        encoding that UUID gives back the same string (i.e. only the
        canonical ShortUUID of a UUID is accepted)

      Returns:
      - `{:ok, shortuuid}` on success
      - `:error` on failure
      """
      @impl true
      @spec cast(uuid() | shortuuid() | any()) :: {:ok, shortuuid()} | :error
      def cast(value), do: unquote(__MODULE__).cast(@encoder, value)

      @doc """
      Loads a binary UUID from the database and converts it to ShortUUID format.

      Returns:
      - `{:ok, shortuuid}` on success
      - `:error` on failure

      Raises an `ArgumentError` if given a string UUID instead of binary.
      """
      @impl true
      @spec load(raw() | any()) :: {:ok, shortuuid()} | :error
      def load(value), do: unquote(__MODULE__).load(@encoder, value)

      @doc """
      Dumps a ShortUUID or standard UUID to binary format for database storage.

      Accepts the same values as `cast/1`:
      - ShortUUID strings
      - Standard UUID strings

      Returns:
      - `{:ok, binary_uuid}` on success
      - `:error` on failure
      """
      @impl true
      @spec dump(shortuuid() | uuid() | any()) :: {:ok, raw()} | :error
      def dump(value), do: unquote(__MODULE__).dump(@encoder, value)

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

      Raises a `RuntimeError` if the encoder fails to encode the generated UUID.
      """
      @spec generate() :: shortuuid()
      def generate, do: unquote(__MODULE__).generate(@encoder)

      @doc """
      Generates a random ShortUUID string for use in primary keys.

      Raises a `RuntimeError` if the encoder fails to encode the generated UUID.

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

  # The functions below implement the callbacks of the generated types. They
  # live here rather than in the `quote` above so they are not duplicated into
  # every type module, and so the compiler does not type-check them against one
  # specific encoder.

  @doc false
  def cast(encoder, <<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid) do
    with {:ok, casted} <- Ecto.UUID.cast(uuid) do
      encode(encoder, casted)
    end
  end

  def cast(encoder, shortuuid) when is_binary(shortuuid) do
    with {:ok, _uuid} <- decode(encoder, shortuuid) do
      {:ok, shortuuid}
    end
  end

  def cast(_encoder, _value), do: :error

  @doc false
  def load(encoder, value) do
    with {:ok, uuid} <- Ecto.UUID.load(value) do
      encode(encoder, uuid)
    end
  end

  @doc false
  def dump(_encoder, <<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid) do
    Ecto.UUID.dump(uuid)
  end

  def dump(encoder, shortuuid) when is_binary(shortuuid) do
    with {:ok, uuid} <- decode(encoder, shortuuid) do
      Ecto.UUID.dump(uuid)
    end
  end

  def dump(_encoder, _value), do: :error

  @doc false
  def generate(encoder) do
    uuid = Ecto.UUID.generate()

    case encoder.encode(uuid) do
      {:ok, shortuuid} when is_binary(shortuuid) ->
        shortuuid

      other ->
        raise "#{inspect(encoder)}.encode/1 failed to encode generated UUID " <>
                "#{inspect(uuid)}, got: #{inspect(other)}"
    end
  end

  # The default ShortUUID encoder only ever produces 22-character strings, so
  # anything of another length is rejected without decoding it.
  defp decode(ShortUUID, shortuuid) when byte_size(shortuuid) != 22, do: :error

  # Decodes a ShortUUID and checks that the result is a valid UUID and that
  # encoding that UUID gives back exactly the same string. The round trip
  # rejects input the decoder tolerates but would never produce itself
  # (truncated or padded strings, values wrapping around 128 bits, other
  # letter cases, ...), so every accepted ShortUUID is the canonical encoding
  # of its UUID. Returns the hex-encoded UUID.
  defp decode(encoder, shortuuid) do
    with {:ok, uuid} <- call_decode(encoder, shortuuid),
         {:ok, uuid} <- Ecto.UUID.cast(uuid),
         {:ok, ^shortuuid} <- encode(encoder, uuid) do
      {:ok, uuid}
    else
      _ -> :error
    end
  end

  # A decoder that has no clause matching the input (e.g. one without a
  # catch-all `decode/1` clause) is treated as rejecting the input rather
  # than crashing the caller.
  defp call_decode(encoder, shortuuid) do
    encoder.decode(shortuuid)
  rescue
    error in FunctionClauseError ->
      if error.module == encoder and error.function == :decode and error.arity == 1 do
        :error
      else
        reraise error, __STACKTRACE__
      end
  end

  defp encode(encoder, uuid) do
    case encoder.encode(uuid) do
      {:ok, shortuuid} when is_binary(shortuuid) -> {:ok, shortuuid}
      _ -> :error
    end
  end
end
