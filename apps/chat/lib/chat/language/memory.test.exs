defmodule Chat.Language.Memory.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.Memory

  alias Chat.Language.Memory

  test "load from default memory" do
    assert nil |> Memory.load(:a) == :error
  end

  test "store in default memory" do
    assert nil |> Memory.store(:a, 5) == nil
  end

  test "load many from default memory" do
    assert nil |> Memory.load_many([:a, :b, :c]) == %{}
  end

  test "load all from default memory" do
    assert nil |> Memory.all() == %{}
  end

  test "load from map memory" do
    assert %{} |> Memory.load(:a) == :error
  end

  test "store in map memory" do
    assert %{} |> Memory.store(:a, 5) == %{a: 5}
  end

  test "store and load in map memory" do
    assert %{} |> Memory.store(:a, 5) |> Memory.load(:a) == {:ok, 5}
  end

  test "load many from map memory" do
    assert %{a: 1, b: 2, c: 3} |> Memory.load_many([:a, :b]) == %{a: 1, b: 2}
  end

  test "load all from map memory" do
    expected = %{a: 1, b: 2, c: 3}
    assert expected |> Memory.all() == expected
  end
end
