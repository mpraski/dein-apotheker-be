defmodule Chat.Scenario.Loader do
  @excel Xlsxir

  @excel_ext ".xlsx"
  @scenario_file "Scenario.xlsx"
  @process_directory "processes"

  def load_tables(path) do
    {
      {
        scenario_name,
        scenario_ref
      },
      process_refs
    } = load_refs(path)

    tables = {
      {
        scenario_name,
        read_table(scenario_ref)
      },
      process_refs |> Enum.map(fn {n, r} -> {n, read_table(r)} end)
    }

    close_table(scenario_ref)
    process_refs |> Enum.each(fn {_, r} -> close_table(r) end)

    tables
  end

  defp load_refs(path) do
    {:ok, ref} =
      path
      |> Path.join(@scenario_file)
      |> open_table()

    scenario_name = Path.basename(path)

    refs =
      path
      |> Path.join(@process_directory)
      |> File.ls!()
      |> Stream.map(&Path.join([path, @process_directory, &1]))
      |> Stream.filter(&File.regular?/1)
      |> Stream.map(fn f ->
        n = Path.basename(f, @excel_ext)
        {:ok, ref} = open_table(f)
        {n, ref}
      end)
      |> Enum.to_list()

    {{scenario_name, ref}, refs}
  end

  defp open_table(path) do
    @excel.multi_extract(path, 0)
  end

  defp read_table(ref) do
    @excel.get_list(ref)
  end

  defp close_table(ref) do
    @excel.close(ref)
  end
end
