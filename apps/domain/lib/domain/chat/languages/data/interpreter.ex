defmodule Chat.Languages.Data.Interpreter do
  alias Chat.Data.Database

  defmodule Failure do
    defexception message: "interpretation failure"
  end

  def interpret(program) do
    &interpret_stmt(program, &1)
  end

  defp interpret_stmt({:select, select, database}, databases) do
    with d <- get_database(database, databases) do
      interpret_select(select).(d)
    end
  end

  defp interpret_stmt({:select, select, database, where}, databases) do
    with d <- get_database(database, databases) do
      interpret_select(select).(d)
    end
  end

  defp interpret_select(:all) do
    fn %Database{headers: headers, rows: rows} ->
      {headers, rows}
    end
  end

  defp interpret_select(cols) when is_list(cols) do
    fn %Database{indexed: indexed} ->
      {headers, rows} =
        cols
        |> Stream.map(&{&1, Map.get(indexed, &1)})
        |> Stream.filter(fn {h, l} -> l end)
        |> Enum.unzip()

      rows =
        rows
        |> Stream.zip()
        |> Stream.map(&Tuple.to_list/1)
        |> Enum.to_list()

      {headers, rows}
    end
  end

  defp get_database(database, databases) do
    case Map.fetch(databases, database) do
      {:ok, %Database{} = d} -> d
      _ -> raise Failure, message: "failed to get database #{database}"
    end
  end
end
