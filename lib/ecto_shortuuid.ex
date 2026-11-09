defmodule Ecto.ShortUUID do
  @moduledoc """
  An Ecto type for Short UUID strings.

  Values are stored as `:uuid` in the database and exposed as ShortUUIDs.
  Both ShortUUIDs and regular UUIDs are accepted as input:

      iex> Ecto.ShortUUID.cast("2a162ee5-02f4-4701-9e87-72762cbce5e2")
      {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"}

      iex> Ecto.ShortUUID.cast("9VprZJ9U7Tgg2PJ8BfTAek")
      {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"}

      iex> Ecto.ShortUUID.cast("not a uuid")
      :error

      iex> Ecto.ShortUUID.dump("9VprZJ9U7Tgg2PJ8BfTAek") == Ecto.UUID.dump("2a162ee5-02f4-4701-9e87-72762cbce5e2")
      true

      iex> Ecto.ShortUUID.load(<<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>)
      {:ok, "9VprZJ9U7Tgg2PJ8BfTAek"}

  See `Ecto.ShortUUID.Builder` for types using a custom ShortUUID encoder.
  """
  use Ecto.ShortUUID.Builder, encoder: ShortUUID
end
