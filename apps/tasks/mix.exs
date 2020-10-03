defmodule Tasks.MixProject do
  use Mix.Project

  def project do
    [
      app: :tasks,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: false,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    []
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    []
  end
end
