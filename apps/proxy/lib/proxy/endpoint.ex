defmodule Proxy.Endpoint do
  use Phoenix.Endpoint, otp_app: :proxy

  alias Proxy.Config

  @allowed_content ~w[application/json]

  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.RequestId)

  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:json],
    pass: @allowed_content,
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.Session, Config.session_options(Mix.env()))

  plug(Corsica, Config.corsica_options(Mix.env()))

  plug(Proxy.Router)
end
