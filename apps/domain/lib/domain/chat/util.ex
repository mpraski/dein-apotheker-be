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
end
