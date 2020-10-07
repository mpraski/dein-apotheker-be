defmodule Proxy.Session.Enforce do
  import Plug.Conn

  alias Plug.Conn
  alias Proxy.Session.Store

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    case conn.assigns.user do
      nil ->
        conn
        |> send_resp(:unauthorized, "")
        |> halt()

      user ->
        session = Store.new_or_fetch(user)

        conn |> assign(:session, session)
    end
  end
end
