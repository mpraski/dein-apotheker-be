defmodule Api.User.Plug do
  import Plug.Conn

  alias Plug.Conn
  alias Api.User.Token
  alias Api.User.Journeys
  alias Api.User.Journeys.Journey

  @state :state
  @user :user
  @has_journey :has_journey?

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    user_id =
      conn
      |> get_session(:user_token)
      |> Token.verify()

    case user_id do
      nil ->
        conn |> assign(@has_journey, false)

      {:error, _} ->
        conn |> assign(@has_journey, false)

      {:ok, user_id} ->
        case Journeys.get(user_id) do
          nil ->
            conn |> assign(@has_journey, false)

          %Journey{user: u, states: [s | _]} ->
            conn
            |> assign(@user, u)
            |> assign(@state, s)
            |> assign(@has_journey, true)
        end
    end
  end
end
