defmodule Ecto.ShortUUID do
  @moduledoc """
  An Ecto type for Short UUID strings.
  """
  use Ecto.ShortUUID.Builder, encoder: ShortUUID
end
