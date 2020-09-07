defmodule Chat.Languages.Data.Interpreter do
  alias Chat.State
  alias Chat.Data.Database

  defmodule Context do
    defstruct databases: nil, state: nil
  end

  defmodule Failure do
    defexception message: "interpretation failure"
  end

  def interpret(program) do
    &interpret_stmt(program, &1)
  end

  defp interpret_stmt({:select, select, d}, %Context{databases: ds}) do
    with d <- get_database(d, ds) |> Database.index() do
      d |> interpret_select(select).()
    end
  end

  defp interpret_stmt(
         {:select, select, d, where},
         %Context{databases: ds, state: s}
       ) do
    with d <- get_database(d, ds) do
      d
      |> interpret_where(where, s).()
      |> interpret_select(select).()
    end
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

      Database.new(id, [headers, rows])
    end
  end

  defp interpret_where({op, col, val}, %State{variables: vs}) do
    with op <- logical_op(op),
         val <- data_value(val, vs) do
      fn %Database{id: id, headers: headers, rows: rows} ->
        idx = Enum.find_index(headers, &(&1 == col))
        rows = Enum.filter(rows, &op.(Enum.at(&1, idx), val))

        Database.new(id, [headers | rows]) |> Database.index()
      end
    end
  end

  defp data_value({:lit, l}, _), do: l

  defp data_value({:var, n}, variables) do
    case Map.fetch(variables, n) do
      {:ok, v} -> v
      nil -> raise Failure, message: "failed to get #{n} variable, not defined"
    end
  end

  defp logical_op(:equals), do: &:erlang.==/2

  defp logical_op(:not_equals), do: &:erlang."/="/2

  defp get_database(database, databases) do
    case Map.fetch(databases, database) do
      {:ok, %Database{} = d} -> d
      _ -> raise Failure, message: "failed to get database #{database}"
    end
  end
end
