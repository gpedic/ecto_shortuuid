# Changelog

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
