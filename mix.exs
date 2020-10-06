defmodule DeinApotheker.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        dein_apotheker: [
          include_executables_for: [:unix],
          applications: [
            proxy: :permanent,
            chat: :permanent
          ]
        ]
      ],
      preferred_cli_env: [test_all: :test]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:credo, "~> 1.2", only: [:dev, :test], runtime: false},
      {:typed_struct, "~> 0.2.1"}
    ]
  end
end
