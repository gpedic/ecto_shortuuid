# Compiles the prefixed-ID example from the README ("Approach 2"), so the
# tests below exercise exactly the code users copy.
readme = File.read!(Path.expand("../../README.md", __DIR__))

elixir_blocks =
  ~r/^```elixir\n(.*?)^```$/ms
  |> Regex.scan(readme, capture: :all_but_first)
  |> List.flatten()

[example] = Enum.filter(elixir_blocks, &String.contains?(&1, "defmodule MyApp.UserID do"))
[iex_session] = Enum.filter(elixir_blocks, &String.contains?(&1, "iex> MyApp.Types.UserID"))
[marker] = Enum.filter(elixir_blocks, &String.contains?(&1, "def __shortuuid__ do"))

Code.compile_string(example, "README.md")

# The canonical marker snippet, added to a copy of the example. Its
# `@impl true` needs a ShortUUID.Behaviour with the 4.3 callback, so it is
# dropped here to stay warning-free on shortuuid 4.2.
marked_example =
  example
  |> String.replace("defmodule MyApp.UserID do", "defmodule MyApp.MarkedUserID do")
  |> String.replace("defmodule MyApp.Types.UserID do", "defmodule MyApp.Types.MarkedUserID do")
  |> String.replace("encoder: MyApp.UserID", "encoder: MyApp.MarkedUserID")
  |> String.replace(
    ~r/^end\n\n# The Ecto type/m,
    String.replace(marker, "@impl true\n", "") <> "end\n\n# The Ecto type",
    global: false
  )

Code.compile_string(marked_example, "README.md")

defmodule Ecto.ShortUUID.ReadmeExampleTest do
  use ExUnit.Case, async: true

  alias MyApp.Types.UserID, as: Type

  @iex_session iex_session
  @test_uuid "2a162ee5-02f4-4701-9e87-72762cbce5e2"
  @test_id "usr_9VprZJ9U7Tgg2PJ8BfTAek"

  test "the iex session in the README is accurate" do
    pairs =
      ~r/^iex> (.+)\n(.+)$/m
      |> Regex.scan(@iex_session, capture: :all_but_first)

    assert length(pairs) == 4

    for [expr, expected] <- pairs do
      {actual, _} = Code.eval_string(expr)
      {expected_value, _} = Code.eval_string(expected)
      assert actual == expected_value, "#{expr} returned #{inspect(actual)}"
    end
  end

  test "round trips random UUIDs" do
    for _ <- 1..200 do
      uuid = Ecto.UUID.generate()
      {:ok, binary} = Ecto.UUID.dump(uuid)

      assert {:ok, "usr_" <> short = id} = Type.cast(uuid)
      assert byte_size(short) == 22
      assert {:ok, id} == Type.cast(String.upcase(uuid))
      assert {:ok, id} == Type.cast(id)
      assert {:ok, binary} == Type.dump(id)
      assert {:ok, binary} == Type.dump(uuid)
      assert {:ok, id} == Type.load(binary)
      assert {:ok, uuid} == MyApp.UserID.decode(id)
      assert Type.equal?(id, uuid)
    end
  end

  test "generate/0 and autogenerate/0 produce prefixed IDs" do
    for id <- [Type.generate(), Type.autogenerate()] do
      assert "usr_" <> _ = id
      assert {:ok, id} == Type.cast(id)
      assert {:ok, <<_::128>>} = Type.dump(id)
    end
  end

  test "rejects anything but the prefix followed by a canonical ShortUUID" do
    {:ok, short} = ShortUUID.encode(@test_uuid)

    invalid = [
      # wrong or missing prefix
      "org_" <> short,
      "USR_" <> short,
      "usr" <> short,
      short,
      # a UUID instead of a ShortUUID after the prefix
      "usr_" <> @test_uuid,
      "usr_" <> String.upcase(@test_uuid),
      "usr_" <> String.replace(@test_uuid, "-", ""),
      # malformed ShortUUIDs
      "usr_",
      "usr_garbage",
      "usr_" <> short <> "2",
      "usr_ " <> short,
      " " <> @test_id,
      "usr_" <> String.duplicate("z", 22),
      # invalid UTF-8
      "usr_" <> "😀" <> <<0xFF>> <> String.duplicate("a", 17),
      <<0xFF>> <> @test_id
    ]

    for input <- invalid do
      assert :error == Type.cast(input), "cast(#{inspect(input)})"
      assert :error == Type.dump(input), "dump(#{inspect(input)})"
      assert {:error, _} = MyApp.UserID.decode(input)
    end

    refute Type.equal?(@test_id, "org_" <> short)
  end

  test "rejects non-binaries" do
    for input <- [nil, 1, :usr, ~c"usr_9VprZJ9U7Tgg2PJ8BfTAek", %{}] do
      assert :error == Type.cast(input)
      assert :error == Type.dump(input)
      assert {:error, _} = MyApp.UserID.decode(input)
    end
  end

  test "the bang functions return the value or raise ArgumentError" do
    assert @test_id == MyApp.UserID.encode!(@test_uuid)
    assert @test_uuid == MyApp.UserID.decode!(@test_id)
    assert_raise ArgumentError, fn -> MyApp.UserID.encode!("not-a-uuid") end
    assert_raise ArgumentError, fn -> MyApp.UserID.decode!("org_9VprZJ9U7Tgg2PJ8BfTAek") end
    assert_raise ArgumentError, fn -> MyApp.UserID.decode!("usr_garbage") end
  end

  test "works in a changeset" do
    types = %{id: Type}

    changeset = Ecto.Changeset.cast({%{}, types}, %{"id" => @test_uuid}, [:id])
    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :id) == @test_id

    changeset = Ecto.Changeset.cast({%{}, types}, %{"id" => "org_x"}, [:id])
    refute changeset.valid?
  end

  describe "with the README's __shortuuid__/0 marker" do
    test "behaves the same" do
      for _ <- 1..50 do
        uuid = Ecto.UUID.generate()
        {:ok, id} = Type.cast(uuid)
        assert {:ok, id} == MyApp.Types.MarkedUserID.cast(uuid)
        assert {:ok, id} == MyApp.Types.MarkedUserID.cast(id)
        assert Type.dump(id) == MyApp.Types.MarkedUserID.dump(id)
      end

      assert :error == MyApp.Types.MarkedUserID.cast("org_9VprZJ9U7Tgg2PJ8BfTAek")
      assert :error == MyApp.Types.MarkedUserID.cast("usr_" <> @test_uuid)
    end

    test "describes the encoder" do
      info = MyApp.MarkedUserID.__shortuuid__()
      assert info.canonical
      "usr_" <> short = @test_id
      assert info.encoded_length == String.length(short)
      assert info.base == String.length(info.alphabet)
    end
  end
end
