defmodule Auth.MixProject do
  use Mix.Project

  def project do
    [
      app: :auth,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_pattern: test_pattern(),
      test_paths: if(Mix.env() == :test, do: test_paths(), else: [])
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Auth.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_uuid, "~> 1.2"},
      {:guardian, "~> 2.0"},
      {:account, in_umbrella: true}
    ]
  end

  @test_helper "test_helper.exs"

  def test_pattern, do: "*.test.exs"

  def test_paths(paths \\ [], dir \\ "lib") do
    File.ls!(dir)
    |> Enum.reduce(paths, fn file, paths ->
      file = Path.join(dir, file)
      base = Path.basename(file)

      cond do
        File.dir?(file) -> test_paths(paths, file)
        File.regular?(file) and base == @test_helper -> [dir | paths]
        true -> paths
      end
    end)
  end
end
