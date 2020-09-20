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
      rows: rows
    }
  end

  def new(id) do
    %__MODULE__{
      id: id,
      headers: [],
      rows: []
    }
  end

  def find(%__MODULE__{id: id} = db, column, value) do
    idx = header_index(db, column)

    finder = &(Enum.at(&1, idx) |> elem(1) == value)

    db |> Enum.filter(finder) |> Enum.into(__MODULE__.new(id))
  end

  def count(%__MODULE__{rows: rows}), do: length(rows)

  def header_index(%__MODULE__{headers: headers}, n) do
    headers |> Enum.find_index(&(&1 == n))
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

  def count(%Database{} = d), do: {:ok, Database.count(d)}

  def member?(_, _), do: {:error, __MODULE__}

  def slice(%Database{headers: headers, rows: rows} = d) do
    {:ok, Database.count(d),
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
         IO.inspect(row)
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
