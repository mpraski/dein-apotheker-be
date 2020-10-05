defmodule Api.SessionController do
  use Api, :controller

  alias Plug.Conn

  plug(Api.User.Plug)

  action_fallback(FallbackController)

  def session(%Conn{} = conn, _params) do
    code = if conn.assigns.has_session?, do: :ok, else: :not_found

    conn
    |> send_resp(code, "")
    |> halt()
  end
end
