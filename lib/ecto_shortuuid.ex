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

  # Provide custom casting rules.
  @spec cast(shortuuid57 | uuid | any) :: {:ok, shortuuid57} | :error
  def cast(<<_::176>> = shortuuid) when is_binary(shortuuid) do
    {:ok, shortuuid}
  end

  def cast(<<_::288>> = uuid) do
    case UUID.cast(uuid) do
      :error -> :error
      {:ok, casted} -> ShortUUID.encode(casted)
    end
  end

  def cast(_), do: :error

  @doc """
  Converts a binary UUID into a ShortUUID string.
  """
  @spec load(binary) :: {:ok, binary} | :error
  def load(<<_::128>> = uuid) do
    case resp = ShortUUID.encode(uuid) do
      {:ok, _} -> resp
      _ -> :error
    end
  end

  def load(_), do: :error

  @doc """
  Converts a string representing a ShortUUID or UUID into a binary.
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
  Generates a ShortUUID string based on a version 4 (random) UUID.
  """
  # @spec generate() :: t
  def generate() do
    {:ok, shortuuid} =
      UUID.generate()
      |> ShortUUID.encode()

    shortuuid
  end

  # Callback invoked by autogenerate fields.
  @doc false
  def autogenerate, do: generate()
end
