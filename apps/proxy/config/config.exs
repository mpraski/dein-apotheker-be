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

config :proxy,
  generators: [context_app: false]

# Configures the endpoint
config :proxy, Proxy.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SkhLSEBG7hcIRVGRQMhMAHYtlVwbHH7LHlWTUUCj6mIhlXgxkVbW2YlSnRutaTzq",
  render_errors: [view: Proxy.ErrorView, accepts: ~w(json)]

config :proxy,
  cache_ttl: :timer.hours(2),
  cache_check: :timer.minutes(30)

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures Elixir's Logger
config :logger, :console,
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
