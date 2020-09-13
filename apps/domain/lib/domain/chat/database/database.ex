defmodule Chat.Database do
  @enforce_keys ~w[id headers rows]a

  defstruct id: nil,
            headers: [],
            rows: [],
            indexed: %{}

  def new(id, [headers | rows]) do
    %__MODULE__{
      id: id,
      headers: Enum.map(headers, &to_atom/1),
      rows: rows
    }
  end

  def index(
        %__MODULE__{
          headers: headers,
          rows: rows
        } = db
      ) do
    %__MODULE__{db | indexed: make_indexed(headers, rows)}
  end

  def count(%__MODULE__{rows: rows}), do: length(rows)

  defp make_indexed(headers, rows) do
    rows
    |> Enum.reduce(%{}, fn r, m ->
      headers
      |> Enum.zip(r)
      |> Enum.reduce(m, fn {h, v}, m ->
        Map.update(m, h, [v], &[v | &1])
      end)
    end)
    |> Enum.map(fn {k, v} -> {k, Enum.reverse(v)} end)
    |> Enum.into(Map.new())
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
       |> Enum.map(&to_map(headers, &1))
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
    reduce(%Database{d | rows: rest}, fun.(to_map(headers, row), acc), fun)
  end

  defp to_map(headers, row) do
    Enum.zip(headers, row) |> Enum.into(Map.new())
  end
end
