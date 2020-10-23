use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :proxy, Proxy.Endpoint,
  http: [port: 8080],
  url: [host: "localhost"],
  server: true

# Configures Elixir's Logger
config :logger, :console,
  level: :warn,
  compile_time_purge_level: :info
