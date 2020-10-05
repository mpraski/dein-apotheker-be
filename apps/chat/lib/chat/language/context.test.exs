defmodule Chat.Language.Context.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.Context

  alias Chat.Language.Context
  alias Chat.Language.Memory

  test "load and store in context" do
    ctx = Context.new(Chat.scenarios(), Chat.databases())

    assert ctx |> Memory.store(:a, 5) |> Memory.load(:a) == {:ok, 5}
  end

  test "load and delete from context" do
    ctx = Context.new(Chat.scenarios(), Chat.databases())

    assert ctx |> Memory.store(:a, 5) |> Memory.delete(:a) == ctx
  end

  test "load many from context" do
    ctx =
      Context.new(Chat.scenarios(), Chat.databases())
      |> Memory.store(:a, 1)
      |> Memory.store(:b, 2)
      |> Memory.store(:c, 3)

    expected = %{a: 1, b: 2, c: 3}

    assert ctx |> Memory.load_many([:a, :b, :c]) == expected
  end

  test "load all from context" do
    ctx =
      Context.new(Chat.scenarios(), Chat.databases())
      |> Memory.store(:a, 1)
      |> Memory.store(:b, 2)
      |> Memory.store(:c, 3)

    expected = %{a: 1, b: 2, c: 3}

    assert ctx |> Memory.all() == expected
  end
end
