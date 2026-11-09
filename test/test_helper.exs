# ShortUUID.Builder (custom alphabets) only exists in shortuuid >= 4.0; the
# suite also runs against shortuuid 3.x, where those tests are excluded.
exclude = if Code.ensure_loaded?(ShortUUID.Builder), do: [], else: [:custom_alphabet]

ExUnit.start(exclude: exclude)
