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
  built with `ShortUUID.Builder` do). It must export `encode/1` and `decode/1`;
  the optional `__shortuuid__/0` is only consulted for its `:canonical` flag
  (see "Canonical encoding" below).

  `:encoder` is the only option. The encoder may be given as a module name or
  as anything that evaluates to one in the type module's body, such as a
  variable, a module attribute or `Application.compile_env/3`. It is checked
  when the type module is compiled: unknown options, a missing or non-module
  `:encoder`, a module that can't be compiled or loaded, or one without
  `encode/1` and `decode/1` raise an `ArgumentError`. The type module depends
  on the encoder at compile time, so it is recompiled when the encoder changes.
  Because the encoder must be compiled first, it can't be defined later in the
  same file as the type that uses it; define it in its own file, above the
  type, or nested inside the type module.

  ## Canonical encoding

  `cast/1` only accepts the canonical ShortUUID of a UUID, i.e. the exact
  string `encoder.encode/1` produces for it. `equal?/2` relies on this, and it
  keeps a single spelling of each ID in changesets and query results.

  How that is ensured depends on the encoder, decided when the type module is
  compiled:

    * `ShortUUID`, and encoders whose `__shortuuid__/0` (an optional
      `ShortUUID.Behaviour` callback added in shortuuid 4.3, implemented by
      `ShortUUID.Builder` modules) returns a map with `canonical: true`,
      guarantee that `decode/1` only accepts canonical strings. `cast/1`
      just decodes.
    * For any other encoder, `cast/1` decodes the string, encodes the result
      again and rejects the input unless it gets the same string back. Input
      the decoder merely tolerates (e.g. a different letter case or extra
      padding) is rejected, at the cost of one extra `encode/1` call.

  `dump/1` only decodes: every string the decoder accepts as a valid UUID is
  dumped, canonical or not.

  A hand-written encoder should only claim `canonical: true` if its `decode/1`
  accepts exactly one string per UUID. Only the `:canonical` key of the
  `__shortuuid__/0` map is read.
  """

  defmacro __using__(opts) do
    encoder = opts |> validate_options!() |> Keyword.fetch!(:encoder)

    # The encoder is stored in an attribute with a name users won't pick, and
    # checked once the type module's body has been evaluated. So it can be
    # given as a variable, module attribute or `Application.compile_env/3`
    # call, and an encoder nested in the type module before `use` is already
    # defined. The same hook defines the encoder's canonical flag (see
    # "Canonical encoding" above).
    quote do
      @behaviour Ecto.Type

      @ecto_shortuuid_encoder unquote(encoder)
      @before_compile {unquote(__MODULE__), :__validate_encoder_module__}

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
      - ShortUUID strings, if they are the canonical encoding of a valid
        UUID (see "Canonical encoding" in `Ecto.ShortUUID.Builder`)

      Returns:
      - `{:ok, shortuuid}` on success
      - `:error` on failure
      """
      @impl true
      @spec cast(term()) :: {:ok, t()} | :error
      def cast(value),
        do: unquote(__MODULE__).cast(@ecto_shortuuid_encoder, __canonical_encoder__(), value)

      @doc """
      Loads a binary UUID from the database and converts it to ShortUUID format.

      Returns:
      - `{:ok, shortuuid}` on success
      - `:error` on failure

      Raises an `ArgumentError` if given a string UUID instead of binary.
      """
      @impl true
      @spec load(term()) :: {:ok, t()} | :error
      def load(value), do: unquote(__MODULE__).load(@ecto_shortuuid_encoder, value)

      @doc """
      Dumps a ShortUUID or standard UUID to binary format for database storage.

      Accepts:
      - Standard UUID strings
      - ShortUUID strings the encoder decodes to a valid UUID. Unlike
        `cast/1`, this does not require the canonical encoding.

      Returns:
      - `{:ok, binary_uuid}` on success
      - `:error` on failure
      """
      @impl true
      @spec dump(term()) :: {:ok, <<_::128>>} | :error
      def dump(value), do: unquote(__MODULE__).dump(@ecto_shortuuid_encoder, value)

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
      `cast/1` guarantees (see "Canonical encoding" in
      `Ecto.ShortUUID.Builder`), and `load/1` always returns the canonical
      encoding. It never calls `decode/1` and never raises unless the
      encoder's `encode/1` does.

      See `c:Ecto.Type.equal?/2`.
      """
      @impl true
      @spec equal?(term(), term()) :: boolean()
      def equal?(term, term), do: true

      def equal?(term1, term2) when is_binary(term1) and is_binary(term2),
        do: unquote(__MODULE__).equal?(@ecto_shortuuid_encoder, term1, term2)

      def equal?(_term1, _term2), do: false

      @doc """
      Generates a ShortUUID string.

      Without options, it encodes a version 4 (random) UUID. Options are
      passed to `Ecto.UUID.generate/1`, e.g. `version: 7` for a time-ordered
      UUIDv7. With the default `ShortUUID` encoder (or any fixed-length
      encoding whose alphabet is in ascending byte order), ShortUUIDs sort in
      the same order as the UUIDs they encode, so UUIDv7-based ones stay
      time-ordered.

      Options require Ecto 3.14 or later; with an older Ecto they raise an
      `ArgumentError`. Also raises a `RuntimeError` if the encoder fails to
      encode the generated UUID.
      """
      @spec generate(keyword()) :: t()
      def generate(opts \\ []), do: unquote(__MODULE__).generate(@ecto_shortuuid_encoder, opts)

      @doc """
      Generates a ShortUUID string for use in primary keys, see `generate/1`.

      This is called by Ecto when a record is inserted if the schema has
      `@primary_key {:id, CustomShortUUIDType, autogenerate: true}`, or with
      the options given in `autogenerate: [version: 7]`.
      """
      @impl true
      @spec autogenerate(keyword()) :: t()
      def autogenerate(opts \\ []), do: generate(opts)
    end
  end

  defp validate_options!(opts) do
    unless Keyword.keyword?(opts) do
      raise ArgumentError,
            "use Ecto.ShortUUID.Builder expects a keyword list of options, " <>
              "got: #{Macro.to_string(opts)}"
    end

    case Keyword.validate(opts, [:encoder]) do
      {:ok, opts} ->
        if Keyword.has_key?(opts, :encoder) do
          opts
        else
          raise ArgumentError,
                "use Ecto.ShortUUID.Builder requires an :encoder option, " <>
                  "e.g. `use Ecto.ShortUUID.Builder, encoder: ShortUUID`"
        end

      {:error, unknown} ->
        raise ArgumentError,
              "unknown options given to use Ecto.ShortUUID.Builder: " <>
                "#{inspect(unknown)}. The only option is :encoder"
    end
  end

  @doc false
  defmacro __validate_encoder_module__(env) do
    encoder = Module.get_attribute(env.module, :ecto_shortuuid_encoder)
    Module.delete_attribute(env.module, :ecto_shortuuid_encoder)

    if not is_atom(encoder) or encoder in [nil, true, false] do
      raise ArgumentError,
            "the :encoder given to Ecto.ShortUUID.Builder must be a module, " <>
              "got: #{inspect(encoder)}"
    end

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

        # `require` makes the encoder a compile-time dependency, so the type
        # is checked again and its canonical flag recomputed when it changes.
        quote do
          require unquote(encoder)
          defp __canonical_encoder__, do: unquote(canonical_encoder?(encoder))
        end

      {:error, reason} ->
        raise ArgumentError,
              "the :encoder given to Ecto.ShortUUID.Builder, #{inspect(encoder)}, " <>
                "could not be compiled or loaded (reason: #{inspect(reason)}). " <>
                "If it is defined further down in the same file, move it above " <>
                "the type or into its own file"
    end
  end

  defp canonical_encoder?(ShortUUID), do: true

  defp canonical_encoder?(encoder) do
    function_exported?(encoder, :__shortuuid__, 0) and
      match?(%{canonical: true}, encoder.__shortuuid__())
  end

  # The functions below implement the callbacks of the generated types. They
  # live here rather than in the `quote` above so they are not duplicated into
  # every type module, and so the compiler does not type-check them against one
  # specific encoder.

  @doc false
  def cast(encoder, canonical? \\ true, value)

  def cast(encoder, _canonical?, <<_::64, ?-, _::32, ?-, _::32, ?-, _::32, ?-, _::96>> = uuid) do
    with {:ok, casted} <- Ecto.UUID.cast(uuid) do
      encode(encoder, casted)
    end
  end

  def cast(encoder, true, shortuuid) when is_binary(shortuuid) do
    with {:ok, _uuid} <- decode(encoder, shortuuid) do
      {:ok, shortuuid}
    end
  end

  # The encoder doesn't guarantee that decode/1 only accepts canonical
  # strings, so encode the UUID again and require the same string back. This
  # rejects input the decoder tolerates but would never produce itself
  # (truncated or padded strings, values wrapping around 128 bits, other
  # letter cases, ...).
  def cast(encoder, false, shortuuid) when is_binary(shortuuid) do
    with {:ok, uuid} <- decode(encoder, shortuuid),
         {:ok, ^shortuuid} <- encode(encoder, uuid) do
      {:ok, shortuuid}
    else
      _ -> :error
    end
  end

  def cast(_encoder, _canonical?, _value), do: :error

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
  def generate(encoder, opts \\ []) do
    uuid = generate_uuid(opts)

    case encoder.encode(uuid) do
      {:ok, shortuuid} when is_binary(shortuuid) ->
        shortuuid

      other ->
        raise "#{inspect(encoder)}.encode/1 failed to encode generated UUID " <>
                "#{inspect(uuid)}, got: #{inspect(other)}"
    end
  end

  defp generate_uuid([]), do: Ecto.UUID.generate()

  # Ecto.UUID.generate/1 (and UUIDv7) exists since Ecto 3.14. It's checked at
  # runtime, and called through apply/3, so older Ecto releases still compile
  # this module without warnings.
  defp generate_uuid(opts) when is_list(opts) do
    if Code.ensure_loaded?(Ecto.UUID) and function_exported?(Ecto.UUID, :generate, 1) do
      # credo:disable-for-next-line Credo.Check.Refactor.Apply
      apply(Ecto.UUID, :generate, [opts])
    else
      raise ArgumentError,
            "generating a UUID with options (#{inspect(opts)}) requires Ecto 3.14 or later"
    end
  end

  # The default ShortUUID encoder only ever produces 22-character strings, so
  # anything of another length is rejected without decoding it.
  defp decode(ShortUUID, shortuuid) when byte_size(shortuuid) != 22, do: :error

  # Decodes a ShortUUID and checks that the result is a valid UUID. Returns
  # the lowercase hyphenated UUID.
  defp decode(encoder, shortuuid) do
    with {:ok, uuid} <- call_decode(encoder, shortuuid),
         {:ok, uuid} <- Ecto.UUID.cast(uuid) do
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
