defmodule Api.ChatController do
  use Api, :controller

  alias Plug.Conn
  alias Api.User
  alias Api.User.Token
  alias Api.User.Session
  alias Api.User.Sessions
  alias Api.FallbackController
  alias Chat.Driver

  plug(Api.User.Plug)

  action_fallback(FallbackController)

  def answer(
        %Conn{
          body_params: %{
            "state" => state,
            "answer" => answer
          }
        } = conn,
        _params
      ) do
    if conn.assigns.has_session? do
      conn |> with_session(state, answer)
    else
      conn |> without_session()
    end
  end

  def answer(_conn, _params) do
    {:error, 400, "Badly formed request"}
  end

  def session(%Conn{} = conn, _params) do
    code = if conn.assigns.has_session?, do: :ok, else: :not_found

    conn
    |> send_resp(code, "")
    |> halt()
  end

  defp with_session(conn, state, answer) do
    %Session{
      user: user,
      states: states
    } = conn.assigns.session

    case Map.fetch(states, state) do
      {:ok, state} ->
        context = {Chat.scenarios(), Chat.databases()}

        state = state |> Driver.next(context, answer)

        user |> Sessions.add(state)

        conn |> render("answer.json", state: state, fresh: false)

      :error ->
        {:error, 400, "bad request"}
    end
  end

  defp without_session(conn) do
    state = Driver.initial({Chat.scenarios(), Chat.databases()})

    user_id = User.generate_id()

    user = User.new(user_id)

    token = Token.sign(user_id)

    user |> Sessions.add(state)

    conn
    |> put_session(:user_token, token)
    |> render("answer.json", state: state, fresh: true)
  end
end
