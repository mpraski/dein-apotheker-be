defmodule Proxy.Session.Verify do
  import Plug.Conn

  alias Plug.Conn
  alias Auth.Issuer

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    token = conn |> get_session(:token)

    case Auth.authenticate(token) do
      {:ok, user} ->
        conn |> assign(:user, user)

      {:expiring, user} ->
        {:ok, token} = Issuer.refresh(token)

        conn
        |> put_session(:token, token)
        |> assign(:user, user)

      {:error, _reason} ->
        conn
        |> delete_session(:token)
        |> assign(:user, nil)
    end
  end
end
