# Changelog

**0.4.1**

### Fixes

* Encoder errors no longer leak out of the type. `cast/1` and `load/1` return
  `:error` unless the encoder returns `{:ok, string}` (an `{:error, reason}`
  used to be passed through, which could crash `Ecto.Changeset.cast/4`
  instead of producing an "is invalid" error). `generate/0` and
  `autogenerate/0` raise a `RuntimeError` instead of returning the encoder's
  error message as an ID.
* `cast/1` and `dump/1` reject input the decoder used to tolerate. A
  ShortUUID string is only accepted if the encoder's `decode/1` returns
  `{:ok, uuid}` with a valid UUID, so a custom encoder's decoded value that
  isn't a UUID is rejected by `cast/1` too, not only by `dump/1`. With the
  default `ShortUUID` encoder the string must also be 22 characters long:
  shortuuid 2.x padded shorter strings, so `cast("9VprZJ")`, `cast("")` and
  `dump("")` used to succeed; they now return `:error`. `cast/1` and
  `dump/1` accept exactly the same values.
* A `FunctionClauseError` raised by the encoder's own `decode/1` (no clause
  matching the input) is treated as invalid input and returns `:error`.
* The README "Approach 2" encoder example is fixed (it had no catch-all
  `decode/1` clause).

### Other changes

* `Ecto.ShortUUID` documentation examples are doctested, and the test suite
  covers exact values, custom alphabets, `{:array, Ecto.ShortUUID}`, embeds
  and changesets, and runs against shortuuid 2.1, 3.0 and 4.x.
* Development: benchfella replaced by benchee, dev/test dependencies updated
  (excoveralls 0.18 no longer pulls in hackney), the unused `:logger`
  extra application removed, sobelow, mix_audit and a `mix ci` alias added.
  CI runs Elixir 1.15/1.17/1.20 against shortuuid 2.1.2, 3.0.0 and 4.x,
  plus format, credo, sobelow, dependency audits and dialyzer. Dependabot
  enabled.
* `CHANGELOG.md` is included in the Hex package.

**0.4.0**
* Add `Ecto.ShortUUID.Builder` to define Ecto types for custom ShortUUID
  encoders: `use Ecto.ShortUUID.Builder, encoder: MyEncoder`. `Ecto.ShortUUID`
  is now itself defined with the builder
* Support custom alphabets through `ShortUUID.Builder` or modules implementing
  `ShortUUID.Behaviour` (requires shortuuid 4.1)
* Add documentation for each callback and extend the test suite

**0.3.0**
* Basic support for shortuuid v4, default alphabet only

**0.2.0**
* Add support for using shortuuid v3

**0.1.5**
* Update tests and test coverage
* Use Ecto.UUID.load/1 directly and encode the resulting UUID instead of only accepting 128 bit binaries

**0.1.4**
* Fix a bug where 22 bits strings would fail to cast

**0.1.3**

* implement new Ecto.Type callbacks equal?/2 and embed_as/1

Implement the new default callbacks to avoid compile warnings.
Implementing them is preferable to using `use Ecto.Type` as it
does not affect compatibility with Ecto v2

**0.1.2**

* update shortuuid depedency to ~> 2.1.1
* this new version brings with it performance improvements

shortuuid v2.1.0
```
## EctoShortUUIDBench
benchmark name    iterations   average time
cast/1 ShortUUID   100000000   0.03 µs/op
cast/1 UUID           100000   17.02 µs/op
load/1                500000   5.94 µs/op
dump/1                100000   15.39 µs/op
generate/0            100000   18.84 µs/op
```

shortuuid v2.1.1
```
## EctoShortUUIDBench
benchmark name    iterations   average time
cast/1 ShortUUID   100000000   0.04 µs/op
cast/1 UUID           500000   5.74 µs/op
load/1                500000   3.65 µs/op
dump/1                200000   8.78 µs/op
generate/0            500000   7.53 µs/op
```

**0.1.1**

* update shortuuid dep to v2.1.0 for binary encoding support
* load/1 will now encode the binary directly without creating a string UUID first

**0.1.0**

* initial commit
