defmodule Ecto.ShortUUID.TestEncoding do
  @moduledoc false

  # shortuuid 2.x writes the digits of a ShortUUID least significant first;
  # 3.0 reversed the order. Expected values in the tests are written in the
  # current (>= 3.0) order and reversed here when running against 2.x.
  @legacy ShortUUID.encode("2a162ee5-02f4-4701-9e87-72762cbce5e2") ==
            {:ok, "keATfB8JP2ggT7U9JZrpV9"}

  def legacy?, do: @legacy

  def shortuuid(value), do: if(@legacy, do: String.reverse(value), else: value)
end

Code.ensure_loaded(Ecto.Type)

exclude =
  [
    # ShortUUID.Builder (custom alphabets) only exists in shortuuid >= 4.0.
    custom_alphabet: not Code.ensure_loaded?(ShortUUID.Builder),
    # The documentation examples use the >= 3.0 encoding.
    doc_examples: Ecto.ShortUUID.TestEncoding.legacy?(),
    # Ecto.Type.embedded_dump/3 and embedded_load/3 only exist in Ecto 3.
    embedded_type: not function_exported?(Ecto.Type, :embedded_dump, 3)
  ]
  |> Enum.filter(fn {_tag, exclude?} -> exclude? end)
  |> Keyword.keys()

ExUnit.start(exclude: exclude)
