defmodule Api.User.Plug do
  import Plug.Conn

  alias Plug.Conn
  alias Api.User.Token
  alias Api.User.Session
  alias Api.User.Sessions

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    token = conn |> get_session(:user_token)

    conn = conn |> assign(:has_session?, false)

    case Token.verify(token) do
      {:ok, user_id} ->
        case Sessions.get(user_id) do
          %Session{} = s ->
            conn
            |> assign(:session, s)
            |> assign(:has_session?, true)

          _ ->
            conn
        end

      _ ->
        conn
    end
  end
end
