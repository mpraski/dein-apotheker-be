defmodule Chat.Database.Loader do
  alias Chat.Excel
  alias Chat.Database

  @spec load(any) :: nil
  def load(path) do
    path
    |> File.ls!()
    |> Stream.map(&Path.join(path, &1))
    |> Stream.filter(&File.regular?/1)
    |> Stream.map(&load_database/1)
    |> Stream.map(fn %Database{id: id} = db -> {id, db} end)
    |> Enum.into(Map.new())
  end

  defp load_database(path) do
    {:ok, ref} = Excel.open_table(path)
    table = Excel.read_table(ref)

    id =
      path
      |> Path.basename(Excel.ext())
      |> String.to_atom()

    Database.new(id, table)
  end
end
