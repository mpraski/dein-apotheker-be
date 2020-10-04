defmodule Api.User.Plug do
  import Plug.Conn

  alias Plug.Conn
  alias Api.User.Storage
  alias Api.User.Token

  @state :state
  @has_user :has_user?
  @user_token :user_token

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    user_id =
      conn
      |> get_session(@user_token)
      |> Token.verify()

    case user_id do
      nil ->
        conn |> assign(@has_user, false)

      {:error, _} ->
        conn |> assign(@has_user, false)

      {:ok, user_id} ->
        case Storage.get(user_id) do
          nil ->
            conn |> assign(@has_user, false)

          state ->
            conn
            |> assign(@state, state)
            |> assign(@has_user, true)
        end
    end
  end
end
