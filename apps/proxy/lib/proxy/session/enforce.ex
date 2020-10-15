defmodule Proxy.Session.Enforce do
  @moduledoc """
  Enforce presence of user's session
  """

  import Plug.Conn

  alias Plug.Conn
  alias Proxy.Session.Store

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    case conn.assigns |> Map.get(:user) do
      nil ->
        conn
        |> send_resp(:unauthorized, "")
        |> halt()

      id ->
        session = Store.new_or_fetch(id)

        conn |> assign(:session, session)
    end
  end
end
