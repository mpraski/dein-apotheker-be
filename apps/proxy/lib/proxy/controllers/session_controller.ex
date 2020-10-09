defmodule Proxy.SessionController do
  use Proxy, :controller

  alias Auth.Issuer
  alias Proxy.FallbackController

  action_fallback(FallbackController)

  def new(conn, _params) do
    {:ok, token, _} = Issuer.guest()

    csrf_token = get_csrf_token()

    conn
    |> put_session(:token, token)
    |> render("new.json", csrf_token: csrf_token)
  end

  def has(conn, _params) do
    code = if conn.assigns.user, do: :ok, else: :not_found

    conn
    |> send_resp(code, "")
    |> halt()
  end

  def delete(conn, _params) do
    delete_csrf_token()

    conn
    |> delete_session(:token)
    |> send_resp(:no_content, "")
    |> halt()
  end
end
