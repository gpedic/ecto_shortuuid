[![CI](https://github.com/gpedic/ecto_shortuuid/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/gpedic/ecto_shortuuid/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/gpedic/ecto_shortuuid/badge.svg?branch=master)](https://coveralls.io/github/gpedic/ecto_shortuuid?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/ecto_shortuuid.svg)](https://hex.pm/packages/ecto_shortuuid)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ecto_shortuuid/)
[![License](https://img.shields.io/hexpm/l/ecto_shortuuid.svg)](https://github.com/gpedic/ecto_shortuuid/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/gpedic/ecto_shortuuid.svg)](https://github.com/gpedic/ecto_shortuuid/commits/master)

# Ecto.ShortUUID

Ecto.ShortUUID is a custom [Ecto.Type](https://hexdocs.pm/ecto/Ecto.Type.html#content) which allows for Ecto to automatically encode UUIDs to [ShortUUIDs](https://github.com/gpedic/ex_shortuuid).

ShortUUID is binary-compatible with UUID, so it can be stored in a `uuid` column in a database.

ShortUUIDs can be used alongside `:binary_id` or as drop-in replacement for `:binary_id` primary and foreign keys, basically anywhere Ecto.UUID can be used.

If you're already using `:binary_id`(`Ecto.UUID`) for primary keys it is possible to simply switch from `:binary_id` to using `Ecto.ShortUUID` and vice versa, neither the underlying data nor DB schema need to be changed.

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

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_shortuuid` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_shortuuid, "~> 0.4.0"}
  ]
end
```

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

Starting with version `v0.4.0` Ecto.ShortUUID supports custom alphabets through two approaches.

> Note: Custom alphabets are available in [ShortUUID](https://github.com/gpedic/ex_shortuuid) starting from version 4.0.0, and the ShortUUID.Behaviour is available since version 4.1.0.

To ensure you have the right version of ShortUUID for custom alphabets, you can explicitly specify it in your dependencies:

```elixir
def deps do
  [
    {:ecto_shortuuid, "~> 0.4.0"},
    {:shortuuid, "~> 4.1"}  # Explicitly specify for custom alphabets/behaviors
  ]
end
```

### Approach 1: Using ShortUUID.Builder

You can define a custom ShortUUID module with a specific alphabet using `ShortUUID.Builder`, then create a custom Ecto type with `Ecto.ShortUUID.Builder`:

```elixir
# Define a custom ShortUUID implementation with a specific alphabet
defmodule MyApp.Base58UUID do
  use ShortUUID.Builder, alphabet: :base58
end

# Create a custom Ecto type that uses your ShortUUID implementation
defmodule MyApp.Base58EctoUUID do
  use Ecto.ShortUUID.Builder, module: MyApp.Base58UUID
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

For more control, you can implement the `ShortUUID.Behaviour` (available since [ShortUUID](https://github.com/gpedic/ex_shortuuid) v4.1.0) directly:

```elixir
defmodule MyApp.CustomShortUUID do
  @behaviour ShortUUID.Behaviour
  
  @impl true
  def encode(uuid) do
    # Your custom implementation
    {:ok, "custom-" <> uuid}
  end
  
  @impl true
  def encode!(uuid) do
    case encode(uuid) do
      {:ok, encoded} -> encoded
      {:error, reason} -> raise ArgumentError, message: reason
    end
  end
  
  @impl true
  def decode("custom-" <> uuid) do
    # Your custom implementation
    {:ok, uuid}
  end
  
  @impl true
  def decode!(encoded) do
    case decode(encoded) do
      {:ok, decoded} -> decoded
      {:error, reason} -> raise ArgumentError, message: reason
    end
  end
end

# Create an Ecto type with your custom implementation
defmodule MyApp.CustomEctoUUID do
  use Ecto.ShortUUID.Builder, module: MyApp.CustomShortUUID
end
```

This gives you complete control over encoding and decoding while maintaining compatibility with Ecto.

## Documentation

Additional documentation can
be found at [https://hexdocs.pm/ecto_shortuuid](https://hexdocs.pm/ecto_shortuuid).

