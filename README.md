[![Build Status](https://travis-ci.com/gpedic/ecto_shortuuid.svg?branch=master)](https://travis-ci.com/gpedic/ecto_shortuuid)
[![Coverage Status](https://coveralls.io/repos/github/gpedic/ecto_shortuuid/badge.svg?branch=master)](https://coveralls.io/github/gpedic/ecto_shortuuid?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/ecto_shortuuid.svg)](https://hex.pm/packages/ecto_shortuuid)

# Ecto.ShortUUID

Ecto.ShortUUID is a custom [Ecto.Type](https://hexdocs.pm/ecto/Ecto.Type.html#content) which allows for Ecto to automatically encode UUIDs to [ShortUUIDs](https://github.com/gpedic/ex_shortuuid).

ShortUUID is binary-compatible with UUID, so it can be stored in a `uuid` column in a database.

ShortUUIDs can be used alongside `:binary_id` or as drop-in replacement for `:binary_id` primary and foreign keys, basically anywhere Ecto.UUID can be used.

If you're already using `:binary_id`(`Ecto.UUID`) for primary keys it is possible to simply switch from `:binary_id` to using `Ecto.ShortUUID` and vice versa, neither the underlying data nor DB schema need to be changed.

For example we can see that calls to `Ecto.ShortUUID.dump/1` and `Ecto.UUID.dump/1` will  return the same binary in the following case:

```elixir
# let's get the encoded value
iex> Ecto.ShortUUID.cast("2a162ee5-02f4-4701-9e87-72762cbce5e2")
{:ok, "keATfB8JP2ggT7U9JZrpV9"}

# and show off that dump/1 works with both ShortUUIDs and UUIDs
iex> Ecto.ShortUUID.dump("keATfB8JP2ggT7U9JZrpV9")
{:ok, <<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>}

# dump/1 continues to work with regular UUIDs
iex> Ecto.ShortUUID.dump("2a162ee5-02f4-4701-9e87-72762cbce5e2")
{:ok, <<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>}

iex> Ecto.UUID.dump("2a162ee5-02f4-4701-9e87-72762cbce5e2")
{:ok, <<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>}

# when a key is retrieved load/1 is called
# with the binary representation of the UUID 2a162ee5-02f4-4701-9e87-72762cbce5e2
iex> Ecto.ShortUUID.load(<<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>)
{:ok, "keATfB8JP2ggT7U9JZrpV9"}

# the same binary key continues to work with Ecto.UUID
iex> Ecto.UUID.load(<<42, 22, 46, 229, 2, 244, 71, 1, 158, 135, 114, 118, 44, 188, 229, 226>>)
{:ok, "2a162ee5-02f4-4701-9e87-72762cbce5e2"}
```
We can see that `Ecto.ShortUUID.dump/1` is backwards compatible and still accepts regular `UUIDs` and that the value stored in the DB is exactly the same as when using the regular `:binary_id` type.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_shortuuid` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_shortuuid, "~> 0.1"}
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


## Documentation

Additional documentation can
be found at [https://hexdocs.pm/ecto_shortuuid](https://hexdocs.pm/ecto_shortuuid).

