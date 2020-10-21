defmodule Proxy.Config do
  @moduledoc """
  Config holds env-dependent endpoint config
  """

  alias Proxy.Session.Store

  @session [
    store: :cookie,
    http_only: true,
    max_age: div(Store.ttl(), 1000),
    key: "_session_key",
    signing_salt: "Q+aBTFr8"
  ]

  @corsica [
    allow_headers: ["content-type", "x-csrf-token"]
  ]

  def corsica_options(:prod) do
    Keyword.merge(@corsica,
      origins: "https://dein-apotheker.online"
    )
  end

  def corsica_options(_) do
    Keyword.merge(@corsica,
      origins: ["http://127.0.0.1:8081", "http://localhost:8081"],
      allow_credentials: true
    )
  end

  def session_options(:prod) do
    Keyword.merge(@session,
      secure: true,
      extra: "SameSite=Strict"
    )
  end

  def session_options(_) do
    Keyword.merge(@session,
      secure: false,
      extra: "SameSite=None"
    )
  end
end
