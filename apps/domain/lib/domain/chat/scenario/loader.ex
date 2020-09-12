defmodule Chat.Scenario.Loader do
  alias Chat.Excel

  @scenario_file "Scenario.xlsx"
  @process_directory "processes"

  def load(path) do
    path
    |> File.ls!()
    |> Stream.map(&Path.join([path, &1]))
    |> Stream.filter(&File.dir?/1)
    |> Stream.map(fn p ->
      n = Path.basename(p)

      scenario =
        p
        |> load_refs()
        |> load_tables()

      {String.to_atom(n), scenario}
    end)
    |> Enum.into(Map.new())
  end

  defp load_refs(path) do
    {:ok, ref} =
      path
      |> Path.join(@scenario_file)
      |> Excel.open_table()

    scenario_name = Path.basename(path)

    refs =
      path
      |> Path.join(@process_directory)
      |> File.ls!()
      |> Stream.map(&Path.join([path, @process_directory, &1]))
      |> Stream.filter(&File.regular?/1)
      |> Stream.map(fn f ->
        n = Path.basename(f, Excel.ext())
        {:ok, ref} = Excel.open_table(f)
        {n, ref}
      end)
      |> Enum.to_list()

    {{scenario_name, ref}, refs}
  end

  defp load_tables({
         {
           scenario_name,
           scenario_ref
         },
         process_refs
       }) do
    tables = {
      {
        scenario_name,
        Excel.read_table(scenario_ref)
      },
      process_refs |> Enum.map(fn {n, r} -> {n, Excel.read_table(r)} end)
    }

    Excel.close_table(scenario_ref)
    process_refs |> Enum.each(fn {_, r} -> Excel.close_table(r) end)

    tables
  end
end
