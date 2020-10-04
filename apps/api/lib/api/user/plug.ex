defmodule Api.User.Plug do
  import Plug.Conn

  alias Plug.Conn
  alias Api.User.Token
  alias Api.User.Journeys
  alias Api.User.Journeys.Journey

  @has_journey :has_journey?
  @state :state
  @user :user

  def init(_params) do
  end

  def call(
        %Conn{
          body_params: %{
            "state" => state,
            "answer" => answer
          }
        } = conn,
        _params
      ) do
    user_id =
      conn
      |> get_session(:user_token)
      |> Token.verify()

    conn =
      %Conn{conn | params: answer}
      |> assign(@has_journey, false)

    case user_id do
      {:ok, user_id} ->
        case Journeys.get(user_id) do
          %Journey{user: u, states: ss} ->
            case Map.fetch(ss, state) do
              {:ok, s} ->
                conn
                |> assign(@user, u)
                |> assign(@state, s)
                |> assign(@has_journey, true)

              :error ->
                conn
            end

          _ ->
            conn
        end

      _ ->
        conn
    end
  end
end
