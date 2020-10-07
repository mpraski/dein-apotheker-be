defmodule Proxy.SessionController do
  use Proxy, :controller

  alias Auth.Issuer
  alias Proxy.FallbackController

  action_fallback(FallbackController)

  def new(conn, _params) do
    {:ok, token, _} = Issuer.guest()

    conn
    |> put_session(:token, token)
    |> send_resp(:created, "")
    |> halt()
  end

  def has(conn, _params) do
    code = if conn.assigns.user, do: :ok, else: :not_found

    conn
    |> send_resp(code, "")
    |> halt()
  end
end
