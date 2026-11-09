# Changelog

**1.0.0**

Upgrading from 0.4.0? Read the 0.4.1 entry below too: its stricter `cast/1`
and `dump/1` and its encoder error handling are part of 1.0 as well.

### Breaking changes

* **Requirements:** Elixir `~> 1.15`, Ecto `~> 3.10` and shortuuid `~> 4.3`.
  Ecto 2.x, shortuuid 2.x and shortuuid 3.x are no longer supported.
  shortuuid 2.x encodes the default alphabet in the reverse digit order, so
  IDs generated with it differ from the 3.x/4.x ones.
* **`cast/1` only accepts the canonical encoding of a UUID**, i.e. the string
  `encode/1` produces for it. For the default `ShortUUID` encoder, and for
  encoders whose `__shortuuid__/0` (an optional `ShortUUID.Behaviour`
  callback, defined by `ShortUUID.Builder` modules) returns `canonical: true`,
  the decoder already guarantees this, so `cast/1` just decodes. For any
  other encoder, `cast/1` now encodes the decoded UUID again and rejects the
  input unless that gives back the same string, so input a custom decoder
  merely tolerates (e.g. an uppercase UUID behind a custom prefix) is
  rejected. This costs one extra
  `encode/1` call per `cast/1` of a ShortUUID string for such encoders.
  Which path a type takes is decided when it is compiled. `dump/1` is
  unchanged: it accepts anything the decoder turns into a valid UUID.
* **Options and the encoder are validated at compile time.**
  `use Ecto.ShortUUID.Builder` now raises an `ArgumentError` if it is given
  options other than `:encoder` (previously ignored) or something other than a
  keyword list, if the `:encoder` option is missing (previously a `KeyError`),
  or if the encoder isn't a module, can't be compiled or loaded, or doesn't
  export `encode/1` and `decode/1`. Such encoders used to compile and only
  fail on first use. This applies however the encoder is given: a module
  name, a variable, a module attribute or `Application.compile_env/3`. A type
  module can still be its own encoder (`encoder: __MODULE__`). The encoder must be compiled before the type that
  uses it, so it can't be defined further down in the same file (it can be
  nested inside the type module). The check adds a compile-time dependency
  from the type to the encoder: the type is recompiled whenever the encoder
  changes, and an encoder that depends on the type at compile time is
  rejected.
* **No more names injected into type modules.** `use Ecto.ShortUUID.Builder`
  no longer runs `alias Ecto.UUID` in the caller (which shadowed the caller's
  own `UUID` alias), no longer sets an `@encoder` attribute (a type module
  could not use that name for its own attribute) and no longer defines the
  `uuid/0`, `shortuuid/0` and `raw/0` types. Each type module defines a single `t/0` type
  (`String.t()`); specs use `t()`/`term()`.
* **`equal?/2` compares IDs, not strings.** A ShortUUID and the hyphenated UUID
  it encodes (in any letter case) are now equal, so e.g.
  `Ecto.Changeset.change(struct, id: uuid_string)` no longer records a change
  when the ID is the same. Identical terms remain equal and two different
  non-UUID strings are never equal, without any decoding; only when one side
  is UUID-shaped is it encoded and compared. This relies on every ShortUUID
  accepted by `cast/1` being the canonical encoding of its UUID.

### Upgrade notes

* Make sure your project runs on Elixir 1.15+, Ecto 3.10+ and shortuuid
  4.3+. The default encoding is identical in shortuuid 3.x and 4.x, so stored
  and exposed IDs do not change when upgrading from 3.x.
* Make sure every encoder passed to `Ecto.ShortUUID.Builder` exists and
  exports `encode/1` and `decode/1`, and define it in its own file, above the
  type using it or nested inside it. It must not depend on the type at
  compile time. Remove any options other than `:encoder`.
* If a custom decoder accepts several spellings of the same ID, `cast/1` now
  only accepts the one `encode/1` produces (`dump/1` still accepts them all);
  normalise such input before casting. Only declare `canonical: true` in
  `__shortuuid__/0` if `decode/1` accepts exactly one string per UUID.
* Replace references to `MyType.uuid()`, `MyType.shortuuid()` or
  `MyType.raw()` in your specs with `MyType.t()` (or `Ecto.UUID.t()` /
  `<<_::128>>`).
* If a module calling `use Ecto.ShortUUID.Builder` relied on the injected
  `UUID` alias, call `Ecto.UUID` explicitly or add `alias Ecto.UUID` yourself.
* Code that compared values with `MyType.equal?/2` and expected a UUID and its
  ShortUUID to differ needs to compare the strings directly.

### New

* `generate/1` and `autogenerate/1` take options, which are passed to
  `Ecto.UUID.generate/1` (Ecto 3.14+). `autogenerate: [version: 7]` on a
  primary key now generates UUIDv7-based ShortUUIDs instead of failing at
  insert with an `UndefinedFunctionError`. With the default encoder they sort
  in time order. On older Ecto releases, `generate/1` with options raises an
  `ArgumentError`, while Ecto itself ignores `autogenerate` options, so the
  primary key is left `nil` on insert. `generate/0` and `autogenerate/0` are
  unchanged.

### Other changes

* Malformed input such as invalid UTF-8 makes `cast/1` and `dump/1` return
  `:error`; with shortuuid before 4.2 it could raise an `ArgumentError`.
* The README's custom encoder example is now a strict prefixed ID
  (`usr_9VprZJ9U7Tgg2PJ8BfTAek`), compiled and tested straight from the
  README.
* `equal?/2` is covered by StreamData property tests; the suite no longer
  needs to special-case older shortuuid releases.
* CI runs Elixir 1.15/1.17/1.20, plus Ecto 3.10.0 on Elixir 1.15.

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
