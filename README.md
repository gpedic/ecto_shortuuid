[![CI](https://github.com/gpedic/ecto_shortuuid/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/gpedic/ecto_shortuuid/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/gpedic/ecto_shortuuid/badge.svg?branch=master)](https://coveralls.io/github/gpedic/ecto_shortuuid?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/ecto_shortuuid.svg)](https://hex.pm/packages/ecto_shortuuid)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ecto_shortuuid/)
[![License](https://img.shields.io/hexpm/l/ecto_shortuuid.svg)](https://github.com/gpedic/ecto_shortuuid/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/gpedic/ecto_shortuuid.svg)](https://github.com/gpedic/ecto_shortuuid/commits/master)

# Ecto.ShortUUID

Ecto.ShortUUID is a custom [Ecto.Type](https://hexdocs.pm/ecto/Ecto.Type.html#content) which allows for Ecto to automatically encode UUIDs to [ShortUUIDs](https://github.com/gpedic/ex_shortuuid).

ShortUUID is binary-compatible with UUID, so it can be stored in a `uuid` column in a database.

ShortUUIDs can be used alongside `:binary_id` or as a replacement for `:binary_id` primary and foreign keys, wherever Ecto.UUID is used for `uuid` columns.

If you're already using `:binary_id` (`Ecto.UUID`) for primary keys, you can switch to `Ecto.ShortUUID` without changing the `uuid` columns or the data in them. Values stored as strings are a different matter, see [Where ShortUUIDs differ from UUIDs](#where-shortuuids-differ-from-uuids).

For example, we can see that calls to `Ecto.ShortUUID.dump/1` and `Ecto.UUID.dump/1` will  return the same binary in the following case:

```elixir
# let's get the encoded value
iex> Ecto.ShortUUID.cast("2a162ee5-02f4-4701-9e87-72762cbce5e2")
{:ok, "9VprZJ9U7Tgg2PJ8BfTAek"}

# and show off that dump/1 works with both ShortUUIDs and UUIDs
iex> Ecto.ShortUUID.dump("9VprZJ9U7Tgg2PJ8BfTAek")
{:ok, <<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>}

# dump/1 continues to work with regular UUIDs
iex> Ecto.ShortUUID.dump("2a162ee5-02f4-4701-9e87-72762cbce5e2")
{:ok, <<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>}

iex> Ecto.UUID.dump("2a162ee5-02f4-4701-9e87-72762cbce5e2")
{:ok, <<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>}

# when a key is retrieved load/1 is called
# with the binary representation of the UUID 2a162ee5-02f4-4701-9e87-72762cbce5e2
iex> Ecto.ShortUUID.load(<<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>)
{:ok, "9VprZJ9U7Tgg2PJ8BfTAek"}

# the same binary key continues to work with Ecto.UUID
iex> Ecto.UUID.load(<<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>)
{:ok, "2a162ee5-02f4-4701-9e87-72762cbce5e2"}
```
We can see that `Ecto.ShortUUID.dump/1` is backwards compatible and still accepts regular `UUIDs` and the value stored in the DB is exactly the same as when using the regular `:binary_id` type.

### Where ShortUUIDs differ from UUIDs

Only the `uuid` column stores the same 16 bytes. Everywhere else your
application sees a different string:

- Embedded schemas, and other values stored as JSON or maps, store the
  ShortUUID string. Switching from `Ecto.UUID` to `Ecto.ShortUUID` still loads
  them, because hyphenated UUIDs are accepted as input, but switching back
  doesn't: `Ecto.UUID` rejects the stored ShortUUIDs, so they have to be
  converted first.
- The same applies to IDs kept outside the database: URLs, API responses,
  caches, logs, other services. Old UUIDs keep working as input to
  `Ecto.ShortUUID`, while ShortUUIDs given to code expecting UUIDs don't.
- `Ecto.ShortUUID.cast/1` accepts hyphenated UUIDs (in any letter case) and
  ShortUUIDs, but not raw 16-byte binaries, which `Ecto.UUID.cast/1` accepts.
  Use `load/1` for those.
- `autogenerate: [version: 7]` and `generate/1` options require Ecto 3.14 or
  later, like `Ecto.UUID.generate/1` itself (see [UUIDv7](#uuidv7)).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_shortuuid` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_shortuuid, "~> 0.4.1"}
  ]
end
```

### Compatibility

| Dependency | Supported versions |
| ---------- | ------------------ |
| Elixir     | `~> 1.15`          |
| Ecto       | `~> 3.10`          |
| shortuuid  | `~> 4.2`           |

Ecto 2.x and shortuuid 2.x/3.x are no longer supported. shortuuid 4.2 is
required: `ShortUUID.Builder` (custom alphabets) and `ShortUUID.Behaviour` are
always available, and decoding never raises on malformed input (such as
invalid UTF-8), so `cast/1` and `dump/1` return `:error` for it instead of
crashing. shortuuid 3.x and 4.x produce
identical encodings for the default alphabet, so upgrading from 3.x does not
change any stored or exposed IDs.

## Example project

You can check out the example project [ecto_shortuuid_example](https://github.com/gpedic/ecto_shortuuid_example) with defined config, schemas and seeds to quickly try out `ecto_shortuuid` for yourself.

## Usage

Using Ecto.ShortUUID is similar to using Ecto.UUID.

### Schema

You can use the ShortUUID for a regular field

```elixir
defmodule Post do
  use Ecto.Schema

  schema "posts" do
    field :test, Ecto.ShortUUID
  end
end
```

To use ShortUUIDs as primary keys we define the @primary_key attribute like this:

```elixir
defmodule MyApp.User do
  use Ecto.Schema

  @primary_key {:id, Ecto.ShortUUID, autogenerate: true}

  schema "users" do
    field :name, :string
    field :age, :integer, default: 0
    has_many :posts, Post
  end
end
```

To avoid having to define the primary key type in every schema in case you're using binary ids throughout you can make ShortUUIDs the default by defining the following in the underlying schema module.

```elixir
# Define a module to be used as base
defmodule MyApp.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, Ecto.ShortUUID, autogenerate: true}
      @foreign_key_type Ecto.ShortUUID
    end
  end
end

# Now use MyApp.Schema to define new schemas
defmodule MyApp.User do
  use MyApp.Schema

  schema "users" do
    field :name, :string
    field :age, :integer, default: 0
    has_many :posts, Post
  end
end
```
This exactly the same as when using `:binary_id` as defined in the [Ecto docs - Schema attributes](https://hexdocs.pm/ecto/Ecto.Schema.html#module-schema-attributes).

### UUIDv7

With Ecto 3.14 or later, `autogenerate` options are passed to
`Ecto.UUID.generate/1`, so primary keys can be time-ordered UUIDv7s:

```elixir
@primary_key {:id, Ecto.ShortUUID, autogenerate: [version: 7]}
```

`Ecto.ShortUUID.generate(version: 7)` does the same outside of schemas.
ShortUUIDs sort in the same order as the UUIDs they encode, so these IDs stay
time-ordered as strings too.

With an older Ecto, `Ecto.ShortUUID.generate(version: 7)` raises an
`ArgumentError`, but `autogenerate: [version: 7]` fails silently: Ecto before
3.14 ignores `autogenerate` options it doesn't recognise (for `Ecto.UUID` too),
so no ID is generated and the primary key is `nil` on insert.


### Migration

The key has to be also defined as :uuid in the migration

```elixir
defmodule MyApp.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :age, :integer
      add :company_id, references(:companies, type: :uuid)

      timestamps
  end
end
```

Alternatively if starting from scratch you can configure the default migration primary key type as:

```elixir
config :app, MyApp.Repo,
  migration_primary_key: [name: :id, type: :binary_id]
```

Read more about config options in the [Ecto docs - Repo Configuration](https://hexdocs.pm/ecto_sql/Ecto.Migration.html#module-repo-configuration).

## Custom Alphabets

Ecto.ShortUUID supports custom alphabets through two approaches.

### Approach 1: Using ShortUUID.Builder

You can define a custom ShortUUID module with a specific alphabet using `ShortUUID.Builder`, then create a custom Ecto type with `Ecto.ShortUUID.Builder`:

```elixir
# Define a custom ShortUUID implementation with a specific alphabet
defmodule MyApp.Base58UUID do
  use ShortUUID.Builder, alphabet: :base58
end

# Create a custom Ecto type that uses your ShortUUID implementation
defmodule MyApp.Base58EctoUUID do
  use Ecto.ShortUUID.Builder, encoder: MyApp.Base58UUID
end

# Use in your schema
defmodule MyApp.User do
  use Ecto.Schema
  
  @primary_key {:id, MyApp.Base58EctoUUID, autogenerate: true}
  @foreign_key_type MyApp.Base58EctoUUID
  
  schema "users" do
    # ...
  end
end
```

[ShortUUID](https://github.com/gpedic/ex_shortuuid) supports these predefined alphabets:
- `:base57_shortuuid` - Default alphabet, omits ambiguous characters like "l", "1", "I", "O", "0"
- `:base58` - Bitcoin alphabet
- `:base62` - Alphanumeric alphabet
- `:base32`, `:base32_hex`, `:base32_crockford`, `:base32_z` - Various base32 encodings
- `:base64`, `:base64_url` - Base64 encodings

You can also define a custom alphabet string with at least 16 unique characters:

```elixir
defmodule MyApp.CustomAlphabetUUID do
  use ShortUUID.Builder, alphabet: "0123456789ABCDEF-_+"
end
```

### Approach 2: Implementing ShortUUID.Behaviour

For more control, you can implement the [`ShortUUID.Behaviour`](https://hexdocs.pm/shortuuid/ShortUUID.Behaviour.html)
yourself. A common reason is a prefixed ID that shows what kind of record it
belongs to, as in `usr_9VprZJ9U7Tgg2PJ8BfTAek`. This encoder wraps the default
`ShortUUID`:

```elixir
defmodule MyApp.UserID do
  @behaviour ShortUUID.Behaviour

  @prefix "usr_"

  @impl true
  def encode(uuid) do
    with {:ok, short} <- ShortUUID.encode(uuid), do: {:ok, @prefix <> short}
  end

  @impl true
  def encode!(uuid) do
    case encode(uuid) do
      {:ok, encoded} -> encoded
      {:error, message} -> raise ArgumentError, message: message
    end
  end

  @impl true
  def decode(@prefix <> short), do: ShortUUID.decode(short)
  # Reject anything else instead of raising
  def decode(_), do: {:error, "Invalid user ID"}

  @impl true
  def decode!(encoded) do
    case decode(encoded) do
      {:ok, decoded} -> decoded
      {:error, message} -> raise ArgumentError, message: message
    end
  end
end

# The Ecto type using it
defmodule MyApp.Types.UserID do
  use Ecto.ShortUUID.Builder, encoder: MyApp.UserID
end
```

```elixir
iex> MyApp.Types.UserID.cast("2a162ee5-02f4-4701-9e87-72762cbce5e2")
{:ok, "usr_9VprZJ9U7Tgg2PJ8BfTAek"}
iex> MyApp.Types.UserID.cast("usr_9VprZJ9U7Tgg2PJ8BfTAek")
{:ok, "usr_9VprZJ9U7Tgg2PJ8BfTAek"}
iex> MyApp.Types.UserID.cast("org_9VprZJ9U7Tgg2PJ8BfTAek")
:error
iex> MyApp.Types.UserID.cast("9VprZJ9U7Tgg2PJ8BfTAek")
:error
```

The decoder only accepts the prefix followed by a valid ShortUUID, which
`ShortUUID.decode/1` only accepts in its canonical form, so every ID has
exactly one spelling. Keep custom decoders that strict.

`cast/1` only accepts the string `encode/1` produces for a UUID. For an
encoder like this one it checks that by encoding the decoded UUID again and
comparing the result, which rejects input a lax decoder would let through
(say, a different letter case). `dump/1` only decodes. An encoder whose
`decode/1` is strict can skip that extra `encode/1` call by declaring itself
canonical with `__shortuuid__/0` (only the `:canonical` key is read). This
works with any shortuuid version; from shortuuid 4.3 on, `__shortuuid__/0` is
an optional `ShortUUID.Behaviour` callback, so you can also mark it
`@impl true` there:

```elixir
def __shortuuid__ do
  # alphabet, base and encoded_length describe the part after the prefix
  %{
    alphabet: "23456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
    base: 57,
    encoded_length: 22,
    canonical: true
  }
end
```

If `encode/1` doesn't return `{:ok, string}`, `cast/1` and `load/1` return
`:error` and `generate/0` raises.

The encoder is checked when the Ecto type is compiled, whether it's given as a
module name, a variable or a module attribute: compilation fails with an
`ArgumentError` on unknown options, if `:encoder` is missing or not a module,
if the module can't be compiled or loaded, or if it doesn't export `encode/1`
and `decode/1`. Define the encoder in its own file, above the Ecto type in the
same file, or nested inside the Ecto type module. The Ecto type is recompiled
whenever its encoder changes.

## Development

`mix ci` runs the same checks as CI: unused/retired/vulnerable dependency
checks (`deps.unlock --check-unused`, `hex.audit`, `deps.audit`), formatting,
compilation with `--warnings-as-errors`, `credo --strict`, `sobelow`,
`dialyzer` and the test suite. Benchmarks can be run with
`mix run bench/shortuuid_bench.exs`.

## Documentation

Additional documentation can
be found at [https://hexdocs.pm/ecto_shortuuid](https://hexdocs.pm/ecto_shortuuid).

