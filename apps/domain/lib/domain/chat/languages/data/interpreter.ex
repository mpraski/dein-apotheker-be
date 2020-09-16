defmodule Chat.Languages.Data.Interpreter do
  alias Chat.State
  alias Chat.Database

  defmodule Context do
    defstruct databases: nil, state: nil
  end

  defmodule Failure do
    defexception message: "interpretation failure"
  end

  def interpret(program) do
    &interpret_stmt(program, %Context{} = &1)
  end

  defp interpret_stmt(
         {:select, select, database},
         %Context{databases: ds}
       ) do
    database
    |> get_database(ds)
    |> index_if_needed(select)
    |> interpret_select(select).()
  end

  defp interpret_stmt(
         {:select, select, database, where},
         %Context{databases: ds, state: s}
       ) do
    database
    |> get_database(ds)
    |> interpret_where(where, s).()
    |> index_if_needed(select)
    |> interpret_select(select).()
  end

  defp interpret_select(:all) do
    fn %Database{} = d -> d end
  end

  defp interpret_select(cols) when is_list(cols) do
    fn %Database{id: id, indexed: indexed} ->
      {headers, rows} =
        cols
        |> Stream.map(&{&1, Map.get(indexed, &1)})
        |> Stream.filter(fn {_, l} -> l end)
        |> Enum.unzip()

      rows =
        rows
        |> Stream.zip()
        |> Stream.map(&Tuple.to_list/1)
        |> Enum.to_list()

      Database.new(id, [headers | rows])
    end
  end

  defp interpret_where({op, col, val}, state) do
    with op <- logical_op(op),
         {:ok, value} <- State.get_var(state, value(val)) do
      fn %Database{id: id, headers: headers, rows: rows} ->
        idx = Enum.find_index(headers, &(&1 == col))
        rows = Enum.filter(rows, &op.(Enum.at(&1, idx), value))

        Database.new(id, [headers | rows])
      end
    end
  end

  defp value({:str, l}), do: l

  defp value({:var, n}), do: n

  defp logical_op(:equals), do: &:erlang.==/2

  defp logical_op(:not_equals), do: &:erlang."/="/2

  defp get_database(database, databases) do
    case Map.fetch(databases, database) do
      {:ok, %Database{} = d} -> d
      _ -> raise Failure, message: "failed to get database #{database}"
    end
  end

  defp index_if_needed(db, :all), do: db

  defp index_if_needed(db, _), do: Database.index(db)
end
