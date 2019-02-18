defmodule EctoShortUUIDBench do
  use Benchfella

  bench "generate/0" do
    Ecto.ShortUUID.generate()
    nil
  end

  # bench "bingenerate/0" do
  #   Ecto.ShortUUID.bingenerate()
  #   nil
  # end

  bench "cast/1 UUID" do
    Ecto.ShortUUID.cast("0160280f-1d70-1568-b097-7bdca2801de3")
  end

  bench "cast/1 ShortUUID" do
    Ecto.ShortUUID.cast("ggAZXFogjWbVWpbbQ4DxF2")
  end

  bench "dump/1" do
    Ecto.ShortUUID.dump("ggAZXFogjWbVWpbbQ4DxF2")
  end

  bench "load/1" do
    Ecto.ShortUUID.load(<<1, 96, 40, 15, 29, 112, 21, 104, 176, 151, 123, 220, 162, 128, 29, 227>>)
  end
end