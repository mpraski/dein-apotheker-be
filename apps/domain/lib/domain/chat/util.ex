defmodule Chat.Util do
  def pluck(item, key) when is_struct(item) do
    item |> Map.from_struct() |> pluck(key)
  end

  def pluck(item, key) when is_map(item) do
    item |> Map.get(key)
  end

  def pop(item, key) when is_struct(item) do
    item |> Map.from_struct() |> pop(key)
  end

  def pop(item, key) when is_map(item) do
    {_, item} = item |> Map.pop(key)
    item
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

  def equal(one, two) when is_list(one) and is_list(two) do
    one -- two == two -- one
  end

  def equal(_, _), do: false

  def any?(items) do
    case items |> Enum.find(fn {_, p} -> p end) do
      {i, p} -> {i, p}
      _ -> nil
    end
  end

  def all?(items) do
    case items |> Enum.find(fn {_, p} -> !p end) do
      {i, p} -> {i, p}
      _ -> nil
    end
  end

  def map_contents(map, f) do
    map |> Enum.map(fn {k, v} -> {k, f.(v)} end) |> Map.new()
  end

  def format(string, bindings) do
    with replace <- fn _, var -> bindings |> Map.get(var, "") end do
      Regex.replace(~r/\{(\w+?)\}/, string, replace)
    end
  end
end
