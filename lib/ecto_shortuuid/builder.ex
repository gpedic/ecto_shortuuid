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

  The specified encoder must be a [ShortUUID](https://github.com/gpedic/ex_shortuuid)
  compatible module, ideally one implementing `ShortUUID.Behaviour` (as modules
  built with `ShortUUID.Builder` do). Only `encode/1` and `decode/1` are used.

  The encoder is checked when the type module is compiled: a missing `:encoder`
  option, a module that can't be compiled or loaded, or one without `encode/1`
  and `decode/1` raises an `ArgumentError` (unless the encoder is only known at
  runtime, e.g. a variable in an unquote fragment). Because the encoder must be
  compiled first, it can't be defined later in the same file as the type that
  uses it; define it in its own file, above the type, or nested inside the type
  module.

  `cast/1` and `dump/1` only accept a ShortUUID string if `encoder.decode/1`
  returns `{:ok, uuid}` with a valid UUID and `encoder.encode/1` turns that
  UUID back into the same string. Every accepted ShortUUID is therefore the
  canonical encoding of its UUID: input the decoder merely tolerates (e.g.
  truncated strings or a different letter case) is rejected.
  """

  defmacro __using__(opts) do
    encoder = opts |> Keyword.get(:encoder) |> Macro.expand(__CALLER__)
    validate_encoder_option!(encoder)

    # Whether a module encoder exists and exports encode/1 and decode/1 is
    # checked once the type module's body has been evaluated, so an encoder
    # nested in the type module before `use` is already defined.
    check_module =
      if is_atom(encoder) do
        quote do: @before_compile({unquote(__MODULE__), :__validate_encoder_module__})
      end

    quote do
      @behaviour Ecto.Type

      @encoder unquote(encoder)
      unquote(check_module)

      @typedoc """
      A ShortUUID string, as produced by the encoder.
      """
      @type t :: String.t()

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
      @spec cast(term()) :: {:ok, t()} | :error
      def cast(value), do: unquote(__MODULE__).cast(@encoder, value)

      @doc """
      Loads a binary UUID from the database and converts it to ShortUUID format.

      Returns:
      - `{:ok, shortuuid}` on success
      - `:error` on failure

      Raises an `ArgumentError` if given a string UUID instead of binary.
      """
      @impl true
      @spec load(term()) :: {:ok, t()} | :error
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
      @spec dump(term()) :: {:ok, <<_::128>>} | :error
      def dump(value), do: unquote(__MODULE__).dump(@encoder, value)

      @doc """
      Dictates how the type should be treated inside embeds.

      See `c:Ecto.Type.embed_as/1`.
      """
      @impl true
      @spec embed_as(term()) :: :self
      def embed_as(_), do: :self

      @doc """
      Checks if two terms represent the same ID.

      Used by Ecto (e.g. `Ecto.Changeset.change/2`) to decide whether a field
      changed. A ShortUUID and the hyphenated UUID it encodes are equal, as are
      two UUIDs that differ only in case.

      Terms that are `==` are always equal. Otherwise, the terms are only
      converted when both are binaries and at least one of them is
      UUID-shaped, in which case they are equal if they `cast/1` to the same
      ShortUUID; two different non-UUID strings are never equal. This relies on
      the encoding being canonical, i.e. exactly one string per UUID, which
      `cast/1` and `dump/1` guarantee: they only accept a ShortUUID string
      that the encoder turns back into itself (see `Ecto.ShortUUID.Builder`),
      so no other spelling of an ID can be stored or loaded. It never calls
      `decode/1` and does not raise on invalid input.

      See `c:Ecto.Type.equal?/2`.
      """
      @impl true
      @spec equal?(term(), term()) :: boolean()
      def equal?(term, term), do: true

      def equal?(term1, term2) when is_binary(term1) and is_binary(term2),
        do: unquote(__MODULE__).equal?(@encoder, term1, term2)

      def equal?(_term1, _term2), do: false

      @doc """
      Generates a ShortUUID string based on a version 4 (random) UUID.

      Raises a `RuntimeError` if the encoder fails to encode the generated UUID.
      """
      @spec generate() :: t()
      def generate, do: unquote(__MODULE__).generate(@encoder)

      @doc """
      Generates a random ShortUUID string for use in primary keys.

      Raises a `RuntimeError` if the encoder fails to encode the generated UUID.

      This is called by Ecto when a record is inserted if the schema has
      `@primary_key {:id, CustomShortUUIDType, autogenerate: true}`.
      """
      @impl true
      @spec autogenerate() :: t()
      def autogenerate do
        generate()
      end
    end
  end

  defp validate_encoder_option!(nil) do
    raise ArgumentError,
          "use Ecto.ShortUUID.Builder requires an :encoder option, " <>
            "e.g. `use Ecto.ShortUUID.Builder, encoder: ShortUUID`"
  end

  defp validate_encoder_option!(encoder) when is_atom(encoder), do: :ok

  defp validate_encoder_option!(encoder) do
    # Anything other than a literal (e.g. a variable inside an unquote
    # fragment) is only known at runtime and can't be checked here.
    if Macro.quoted_literal?(encoder) do
      raise ArgumentError,
            "the :encoder given to Ecto.ShortUUID.Builder must be a module, " <>
              "got: #{Macro.to_string(encoder)}"
    end
  end

  @doc false
  defmacro __validate_encoder_module__(env) do
    encoder = Module.get_attribute(env.module, :encoder)

    case Code.ensure_compiled(encoder) do
      {:module, ^encoder} ->
        missing =
          for {fun, arity} <- [encode: 1, decode: 1],
              not function_exported?(encoder, fun, arity),
              do: "#{fun}/#{arity}"

        if missing != [] do
          raise ArgumentError,
                "the :encoder given to Ecto.ShortUUID.Builder, #{inspect(encoder)}, " <>
                  "does not export #{Enum.join(missing, " and ")}"
        end

      {:error, reason} ->
        raise ArgumentError,
              "the :encoder given to Ecto.ShortUUID.Builder, #{inspect(encoder)}, " <>
                "could not be compiled or loaded (reason: #{inspect(reason)}). " <>
                "If it is defined further down in the same file, move it above " <>
                "the type or into its own file"
    end

    nil
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
  def equal?(encoder, term1, term2) do
    # Thanks to the canonical encoding, comparing the casts of both terms
    # reduces to at most one encode/1 call and no decode/1 calls.
    case {uuid_shaped?(term1), uuid_shaped?(term2)} do
      {true, true} -> same_uuid?(Ecto.UUID.cast(term1), Ecto.UUID.cast(term2))
      {true, false} -> cast(encoder, term1) == {:ok, term2}
      {false, true} -> cast(encoder, term2) == {:ok, term1}
      {false, false} -> false
    end
  end

  defp same_uuid?({:ok, uuid}, {:ok, uuid}), do: true
  defp same_uuid?(_, _), do: false

  defp uuid_shaped?(<<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>>), do: true
  defp uuid_shaped?(_), do: false

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
