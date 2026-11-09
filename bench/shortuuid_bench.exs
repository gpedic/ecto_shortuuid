# Run with: mix run bench/shortuuid_bench.exs
uuid = "0160280f-1d70-1568-b097-7bdca2801de3"
shortuuid = "ggAZXFogjWbVWpbbQ4DxF2"
other_shortuuid = "9VprZJ9U7Tgg2PJ8BfTAek"
binary = <<1, 96, 40, 15, 29, 112, 21, 104, 176, 151, 123, 220, 162, 128, 29, 227>>

Benchee.run(%{
  "generate/0" => fn -> Ecto.ShortUUID.generate() end,
  "cast/1 UUID" => fn -> Ecto.ShortUUID.cast(uuid) end,
  "cast/1 ShortUUID" => fn -> Ecto.ShortUUID.cast(shortuuid) end,
  "dump/1" => fn -> Ecto.ShortUUID.dump(shortuuid) end,
  "load/1" => fn -> Ecto.ShortUUID.load(binary) end,
  "equal?/2 same ShortUUID" => fn -> Ecto.ShortUUID.equal?(shortuuid, shortuuid) end,
  "equal?/2 different ShortUUIDs" => fn -> Ecto.ShortUUID.equal?(shortuuid, other_shortuuid) end,
  "equal?/2 ShortUUID vs UUID" => fn -> Ecto.ShortUUID.equal?(shortuuid, uuid) end
})
