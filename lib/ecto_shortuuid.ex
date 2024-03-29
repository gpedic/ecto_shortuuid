defmodule Ecto.ShortUUID do
  alias Ecto.UUID

  @moduledoc """
  An Ecto type for Short UUID strings.
  """

  @behaviour Ecto.Type

  @typedoc """
  A hex-encoded UUID string.
  """
  @type uuid :: <<_::288>>

  @typedoc """
  A base57 ShortUUID string.
  """
  @type shortuuid57 :: <<_::176>>

  @typedoc """
  A raw binary representation of a UUID.
  """
  @type raw :: <<_::128>>

  @doc """
  The Ecto type.
  """
  def type, do: :uuid

  @doc """
  Casts the given input to ShortUUID

  https://hexdocs.pm/ecto/Ecto.Type.html#c:cast/1
  """
  @spec cast(shortuuid57 | uuid | any) :: {:ok, shortuuid57} | :error
  def cast(<<_::176>> = shortuuid) when is_binary(shortuuid) do
    case ShortUUID.decode(shortuuid) do
      {:ok, _} -> {:ok, shortuuid}
      {:error, _} -> :error
    end
  end

  def cast(<<_::288>> = uuid) do
    case UUID.cast(uuid) do
      :error -> :error
      {:ok, casted} -> ShortUUID.encode(casted)
    end
  end

  def cast(_), do: :error

  @doc """
  Loads a binary UUID into a ShortUUID string.

  https://hexdocs.pm/ecto/Ecto.Type.html#c:load/1
  """
  @spec load(binary) :: {:ok, binary} | :error
  def load(uuid) do
    case UUID.load(uuid) do
      {:ok, uuid} -> ShortUUID.encode(uuid)
      _ -> :error
    end
  end

  @doc """
  Dumps the given string representing a ShortUUID or UUID into a binary.

  https://hexdocs.pm/ecto/Ecto.Type.html#c:dump/1
  """
  @spec dump(shortuuid57 | uuid | any) :: {:ok, raw} | :error
  def dump(<<_::288>> = uuid), do: Ecto.UUID.dump(uuid)

  def dump(<<_::176>> = shortuuid) do
    with {:ok, uuid} <- ShortUUID.decode(shortuuid),
         {:ok, binary_uuid} <- Ecto.UUID.dump(uuid) do
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
  def embed_as(_), do: :self

  @doc """
  Ecto v3 callback
  Checks if two terms are semantically equal.

  https://hexdocs.pm/ecto/Ecto.Type.html#c:equal?/2
  """
  def equal?(term1, term2), do: term1 == term2

  @doc """
  Generates a ShortUUID string based on a version 4 (random) UUID.
  """
  # @spec generate() :: t
  def generate do
    {:ok, shortuuid} =
      UUID.generate()
      |> ShortUUID.encode()

    shortuuid
  end

  # Callback invoked by autogenerate fields.
  @doc false
  def autogenerate, do: generate()
end
