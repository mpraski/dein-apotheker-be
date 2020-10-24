defmodule Chat.Database do
  @moduledoc """
  Database represents an in-memory tabular data store
  """

  use TypedStruct

  typedstruct do
    field(:id, atom(), enforce: true)
    field(:headers, list(atom()), enforce: true, default: [])
    field(:rows, list(list(binary())), enforce: true, default: [])
  end

  def new(id, [headers | rows]) do
    %__MODULE__{
      id: id,
      headers: sanitize_headers(headers),
      rows: sanitize_rows(rows)
    }
  end

  def new(id) do
    %__MODULE__{
      id: id,
      headers: [],
      rows: []
    }
  end

  def select(%__MODULE__{} = db, []) do
    %__MODULE__{db | headers: [], rows: []}
  end

  def select(%__MODULE__{id: id} = db, columns) do
    indices = columns |> Enum.map(&header_index(db, &1))

    mapper = fn r ->
      indices
      |> Enum.reduce([], &[Enum.at(r, &1) | &2])
      |> Enum.reverse()
    end

    db |> Stream.map(mapper) |> Enum.into(new(id))
  end

  def where(%__MODULE__{id: id, headers: hs} = db, column, value) do
    idx = header_index(db, column)

    predicate = &(Enum.at(&1, idx) |> elem(1) == value)

    db |> Stream.filter(predicate) |> Enum.into(new(id, [hs]))
  end

  def where_in(%__MODULE__{id: id, headers: hs} = db, column, values) do
    idx = header_index(db, column)

    predicate = &((Enum.at(&1, idx) |> elem(1)) in values)

    db |> Stream.filter(predicate) |> Enum.into(new(id, [hs]))
  end

  def union(
        %__MODULE__{id: id, headers: h, rows: r1},
        %__MODULE__{id: id, headers: h, rows: r2}
      ) do
    new(id, [h | r1 ++ r2])
  end

  def intersection(
        %__MODULE__{id: id, headers: h, rows: r1},
        %__MODULE__{id: id, headers: h, rows: r2}
      ) do
    new(id, [h | r1 -- r1 -- r2])
  end

  def join(
        %__MODULE__{headers: hs1, id: id} = db1,
        %__MODULE__{headers: hs2} = db2,
        col1,
        col2,
        prefix,
        pred
      ) do
    h1 = header_index(db1, col1)
    h2 = header_index(db2, col2)

    del_idx = width(db1) + h2

    hs = (hs1 ++ Enum.map(hs2, &:"#{prefix}.#{&1}")) |> List.delete_at(del_idx)

    Stream.flat_map(db1, fn r1 ->
      Enum.reduce(db2, [], fn r2, acc ->
        v1 = Enum.at(r1, h1) |> elem(1)
        v2 = Enum.at(r2, h2) |> elem(1)

        if pred.(v1, v2) do
          [r1 ++ r2 | acc]
        else
          acc
        end
      end)
    end)
    |> Stream.map(&List.delete_at(&1, del_idx))
    |> Enum.into(new(id, [hs]))
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

  def single_column_rows(%__MODULE__{rows: rows}) do
    rows |> Enum.flat_map(& &1)
  end

  defp sanitize_headers(headers) do
    headers |> Enum.map(&to_atom/1)
  end

  defp sanitize_rows(rows) do
    rows
    |> Enum.filter(fn r -> !Enum.all?(r, &is_nil/1) end)
    |> Enum.map(&Enum.map(&1, fn r -> to_string(r) end))
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

  def into(original) do
    collector_fun = fn
      %Database{headers: []} = db, {:cont, row} ->
        {headers, row} = Database.from_list(row)
        %Database{db | headers: headers, rows: [row]}

      %Database{rows: rows} = db, {:cont, row} ->
        {_, row} = Database.from_list(row)
        %Database{db | rows: rows ++ [row]}

      db, :done ->
        db

      _, :halt ->
        :ok
    end

    {original, collector_fun}
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
