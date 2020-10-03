defmodule Chat.Database do
  use TypedStruct

  typedstruct do
    field(:id, atom(), enforce: true)
    field(:headers, list(atom()), enforce: true, default: [])
    field(:rows, list(list(binary())), enforce: true, default: [])
  end

  def new(id, [headers | rows]) do
    %__MODULE__{
      id: id,
      headers: headers |> Enum.map(&to_atom/1),
      rows: rows |> Enum.map(&Enum.map(&1, fn r -> to_string(r) end))
    }
  end

  def new(id) do
    %__MODULE__{
      id: id,
      headers: [],
      rows: []
    }
  end

  def where(%__MODULE__{id: id, headers: hs} = db, column, value) do
    idx = header_index(db, column)

    predicate = &(Enum.at(&1, idx) |> elem(1) == value)

    db |> Enum.filter(predicate) |> Enum.into(__MODULE__.new(id, [hs]))
  end

  def union(
        %__MODULE__{id: id, headers: h, rows: r1},
        %__MODULE__{id: id, headers: h, rows: r2}
      ) do
    __MODULE__.new(id, [h | r1 ++ r2])
  end

  def union(
        %__MODULE__{id: id, headers: h, rows: r},
        %__MODULE__{id: id, headers: h, rows: []}
      )
      when length(r) > 0 do
    __MODULE__.new(id, [h | r])
  end

  def union(
        %__MODULE__{id: id, headers: h, rows: []},
        %__MODULE__{id: id, headers: h, rows: r}
      )
      when length(r) > 0 do
    __MODULE__.new(id, [h | r])
  end

  def intersection(
        %__MODULE__{id: id, headers: h, rows: r1},
        %__MODULE__{id: id, headers: h, rows: r2}
      ) do
    __MODULE__.new(id, [h | r1 -- r1 -- r2])
  end

  def intersection(
        %__MODULE__{id: id, headers: h},
        %__MODULE__{id: id, headers: []}
      )
      when length(h) > 0 do
    __MODULE__.new(id, [h | []])
  end

  def intersection(
        %__MODULE__{id: id, headers: []},
        %__MODULE__{id: id, headers: h}
      )
      when length(h) > 0 do
    __MODULE__.new(id, [h | []])
  end

  def join(
        %__MODULE__{id: id, headers: hs1} = db1,
        %__MODULE__{headers: hs2} = db2,
        col1,
        col2,
        prefix,
        pred
      ) do
    prefixer = &:"#{prefix}.#{&1}"

    h1 = __MODULE__.header_index(db1, col1)
    h2 = __MODULE__.header_index(db2, col2)

    del_idx = __MODULE__.width(db1) + h2

    hs = (hs1 ++ Enum.map(hs2, prefixer)) |> List.delete_at(del_idx)

    db1
    |> Enum.flat_map(fn r1 ->
      db2
      |> Enum.map(fn r2 ->
        v1 = Enum.at(r1, h1) |> elem(1)
        v2 = Enum.at(r2, h2) |> elem(1)

        if pred.(v1, v2), do: r1 ++ Enum.map(r2, fn {k, v} -> {prefixer.(k), v} end), else: []
      end)
    end)
    |> Enum.filter(&(!Enum.empty?(&1)))
    |> Enum.map(&List.delete_at(&1, del_idx))
    |> Enum.into(__MODULE__.new(id, [hs]))
  end

  def width(%__MODULE__{headers: headers}), do: length(headers)

  def height(%__MODULE__{rows: rows}), do: length(rows)

  def header_index(%__MODULE__{id: id, headers: headers}, n) do
    headers |> Enum.find_index(&(&1 == n)) || raise "column #{n} does not exist in #{id}"
  end

  def to_list(headers, row) do
    Enum.zip(headers, row)
  end

  def from_list(list) do
    Enum.unzip(list)
  end

  defp to_atom(a) when is_atom(a), do: a

  defp to_atom(a) when is_binary(a), do: String.to_atom(a)
end

defimpl Enumerable, for: Chat.Database do
  alias Chat.Database

  def count(%Database{} = d), do: {:ok, Database.height(d)}

  def member?(_, _), do: {:error, __MODULE__}

  def slice(%Database{headers: headers, rows: rows} = d) do
    {:ok, Database.height(d),
     fn start, len ->
       rows
       |> Enum.slice(start..(start + len))
       |> Enum.map(&Database.to_list(headers, &1))
     end}
  end

  def reduce(%Database{}, {:halt, acc}, _), do: {:halted, acc}

  def reduce(%Database{} = d, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(d, &1, fun)}

  def reduce(%Database{rows: []}, {:cont, acc}, _), do: {:done, acc}

  def reduce(
        %Database{
          rows: [row | rest],
          headers: headers
        } = d,
        {:cont, acc},
        fun
      ) do
    reduce(%Database{d | rows: rest}, fun.(Database.to_list(headers, row), acc), fun)
  end
end

defimpl Collectable, for: Chat.Database do
  alias Chat.Database

  def into(db) do
    {db,
     fn
       %Database{headers: []} = db, {:cont, row} ->
         {headers, row} = Database.from_list(row)
         %Database{db | headers: headers, rows: [row]}

       %Database{rows: rows} = db, {:cont, row} ->
         {_, row} = Database.from_list(row)
         %Database{db | rows: rows ++ [row]}

       db, :done ->
         db

       _, :halt ->
         nil
     end}
  end
end

defimpl String.Chars, for: Chat.Database do
  alias Chat.Database

  def to_string(%Database{rows: rows}) do
    rows
    |> Enum.map(&Enum.join(&1, ", "))
    |> Enum.join("\n")
  end
end

defimpl Chat.Language.Memory, for: Chat.Database do
  alias Chat.Database

  def store(%Database{} = d, _, _), do: d

  def load(%Database{} = d, v) do
    h =
      try do
        Database.header_index(d, v)
      rescue
        _ -> nil
      end

    case h do
      nil -> :error
      h -> {:ok, d |> Enum.map(&(Enum.at(&1, h) |> elem(1)))}
    end
  end

  def load_many(%Database{} = d, vars) do
    vars
    |> Enum.reduce(Map.new(), fn v, acc ->
      case load(d, v) do
        {:ok, c} -> Map.put(acc, v, c)
        :error -> acc
      end
    end)
  end

  def delete(%Database{} = d, _), do: d

  def all(%Database{}), do: Map.new()
end
