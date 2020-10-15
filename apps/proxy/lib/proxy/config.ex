defmodule Proxy.Config do
  alias Proxy.Session.Store

  def corsica_options(:prod) do
    [
      origins: "https://dein-apotheker.online",
      allow_headers: :all
    ]
  end

  def corsica_options(_) do
    [
      origins: ["http://127.0.0.1:8081", "http://localhost:8081"],
      allow_headers: :all,
      allow_credentials: true
    ]
  end

  def session_options(:prod) do
    [
      store: :cookie,
      secure: true,
      http_only: true,
      max_age: div(Store.ttl(), 1000),
      key: "_session_key",
      signing_salt: "Q+aBTFr8",
      extra: "SameSite=Strict"
    ]
  end

  def session_options(_) do
    [
      store: :cookie,
      secure: false,
      http_only: true,
      max_age: div(Store.ttl(), 1000),
      key: "_session_key",
      signing_salt: "Q+aBTFr8",
      extra: "SameSite=None"
    ]
  end
end
