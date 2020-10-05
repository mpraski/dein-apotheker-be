defmodule Api.MixProject do
  use Mix.Project

  def project do
    [
      app: :api,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_pattern: test_pattern(),
      test_paths: if(Mix.env() == :test, do: test_paths(), else: [])
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Api.Application, []},
      extra_applications: [:logger, :runtime_tools, :corsica]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.1"},
      {:elixir_uuid, "~> 1.2"},
      {:corsica, "~> 1.1"},
      {:con_cache, "~> 0.14.0"},
      {:chat, in_umbrella: true}
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
