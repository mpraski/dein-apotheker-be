import Config

config :domain, scenario_path: "../../dein-apotheker-scenarios"

# Configures Elixir's Logger
config :logger, :console,
  level: :warn,
  compile_time_purge_level: :info
