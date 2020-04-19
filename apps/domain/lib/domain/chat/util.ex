defmodule Chat.Util do
  def pluck(item, key) when is_struct(item) do
    item |> Map.from_struct() |> Map.get(key)
  end

  def pluck(item, key) when is_map(item) do
    item |> Map.get(key)
  end

  def index(items) do
    items |> Enum.map(&{&1, nil}) |> Map.new()
  end

  def has_key?(_, nil), do: true
  def has_key?(map, key), do: Map.has_key?(map, key)

  def to_keywords(nil), do: []

  def to_keywords(m) when is_map(m) do
    m |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end

  def equal(:default, _), do: false
  def equal(_, :default), do: false
  def equal(one, two), do: one -- two == [] and two -- one == []
end
