defmodule Domain.MixProject do
  use Mix.Project

  def project do
    [
      app: :domain,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      erlc_paths: [
        "lib/domain/chat/language/compiler"
      ],
      test_pattern: test_pattern(),
      test_paths: if(Mix.env() == :test, do: test_paths(), else: [])
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :xlsxir],
      mod: {Domain.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:xlsxir, "~> 1.6.4"},
      {:benchee, "~> 1.0", only: :dev}
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
