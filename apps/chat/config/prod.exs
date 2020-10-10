import Config

config :chat,
  scenario_path: "../../dein-apotheker-scenarios/scenarios",
  database_path: "../../dein-apotheker-scenarios/databases"

# Configures Elixir's Logger
config :logger, :console,
  level: :warn,
  compile_time_purge_level: :info
