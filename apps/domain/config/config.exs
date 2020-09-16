# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :domain, ecto_repos: [Domain.Repo]

# Configure your database
config :domain, Domain.Repo,
  username: "eat_user",
  password: "qwerty123",
  database: "eat_db",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :domain,
  scenario_path: "local-scenarios",
  database_path: "local-databases"

# Configures Elixir's Logger
config :logger, :console,
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
