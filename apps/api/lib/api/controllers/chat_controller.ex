defmodule Api.ChatController do
  use Api, :controller

  alias Plug.Conn
  alias Api.User
  alias Api.User.Token
  alias Api.User.Journeys
  alias Api.FallbackController
  alias Chat.State
  alias Chat.Driver

  plug(Api.User.Plug)

  action_fallback(FallbackController)

  def answer(
        %Conn{
          body_params: %{
            "answer" => answer
          }
        } = conn,
        _params
      ) do
    if conn.assigns.has_journey? do
      with_journey(conn, answer)
    else
      without_journey(conn)
    end
  end

  def answer(_conn, _params) do
    {:error, 400, "Badly formed request"}
  end

  defp with_journey(conn, answer) do
    %User{} = user = conn.assigns.user
    %State{} = state = conn.assigns.state

    state =
      state
      |> Driver.next(
        {Chat.scenarios(), Chat.databases()},
        answer
      )

    user |> Journeys.progress(state)

    conn |> render("answer.json", state: state, fresh: false)
  end

  defp without_journey(conn) do
    state = Driver.initial({Chat.scenarios(), Chat.databases()})

    user_id = User.generate_id()

    user = User.new(user_id)

    token = Token.sign(user_id)

    user |> Journeys.progress(state)

    conn
    |> put_session(:user_token, token)
    |> render("answer.json", state: state, fresh: true)
  end
end
