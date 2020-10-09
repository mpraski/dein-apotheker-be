defmodule Proxy.Session.Enforce do
  import Plug.Conn

  alias Plug.Conn
  alias Proxy.Session.Store
  alias Account.User

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    case conn.assigns |> Map.get(:user) do
      nil ->
        conn
        |> send_resp(:unauthorized, "")
        |> halt()

      %User{id: id} ->
        session = Store.new_or_fetch(id)

        conn |> assign(:session, session)
    end
  end
end
