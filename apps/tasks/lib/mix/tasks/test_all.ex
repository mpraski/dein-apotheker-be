defmodule Mix.Tasks.TestAll do
  use Mix.Task

  @test "test"
  @test_file ~r/^.*\.test\.exs$/
  @test_helper "test_helper.exs"
  @test_helper_contents "ExUnit.start()"

  @impl true
  def run(_) do
    paths = test_path_candidates()

    paths
    |> Stream.map(&Path.join(&1, @test_helper))
    |> Stream.filter(&(!File.exists?(&1)))
    |> Enum.each(&File.write!(&1, @test_helper_contents))

    Mix.Task.run(@test)

    paths
    |> Stream.map(&Path.join(&1, @test_helper))
    |> Stream.filter(&File.exists?/1)
    |> Enum.each(&File.rm!/1)
  end

  defp test_path_candidates(paths \\ MapSet.new(), dir \\ ".") do
    File.ls!(dir)
    |> Enum.reduce(paths, fn file, paths ->
      file = Path.join(dir, file)
      base = Path.basename(file)

      cond do
        File.dir?(file) -> test_path_candidates(paths, file)
        String.match?(base, @test_file) -> MapSet.put(paths, dir)
        true -> paths
      end
    end)
  end
end
