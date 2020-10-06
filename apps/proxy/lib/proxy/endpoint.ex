defmodule Proxy.Endpoint do
  use Phoenix.Endpoint, otp_app: :proxy

  alias Proxy.Session.Store

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    secure: true,
    http_only: true,
    max_age: div(Store.ttl(), 1000),
    key: "_session_key",
    signing_salt: "Q+aBTFr8"
  ]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:json],
    json_decoder: Phoenix.json_library()
  )

  plug(Proxy.HealthCheck.Plug)
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(:fetch_session)
  plug(Corsica, origins: "*", allow_headers: :all)
  plug(Proxy.Router)
end
