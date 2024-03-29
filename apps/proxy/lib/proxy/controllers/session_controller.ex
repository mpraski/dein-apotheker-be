defmodule Proxy.SessionController do
  use Proxy, :controller

  alias Auth.Issuer
  alias Proxy.FallbackController

  action_fallback(FallbackController)

  def new(conn, _params) do
    {:ok, token, _} = Issuer.guest()

    csrf_token = UUID.uuid4()

    conn
    |> put_session(:token, token)
    |> put_session(:csrf_token, csrf_token)
    |> render("new.json", csrf_token: csrf_token)
  end

  def has(conn, _params) do
    code = if conn.assigns.user, do: :ok, else: :no_content

    conn
    |> send_resp(code, "")
    |> halt()
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:token)
    |> delete_session(:csrf_token)
    |> send_resp(:no_content, "")
    |> halt()
  end
end
