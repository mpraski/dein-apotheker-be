defmodule Api.ChatController do
  use Api, :controller

  alias Plug.Conn
  alias Api.User
  alias Api.User.Token
  alias Api.User.Storage
  alias Api.FallbackController
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
    if conn.assigns.has_user? do
      with_user(conn, answer)
    else
      without_user(conn)
    end
  end

  def answer(_conn, _params) do
    {:error, 400, "Badly formed request"}
  end

  defp with_user(conn, answer) do
    %User{state: state} = conn.assigns.user

    state =
      state
      |> Driver.next(
        {Chat.scenarios(), Chat.databases()},
        answer
      )

    user = %User{conn.assigns.user | state: state}

    Storage.put(user)

    conn |> render("answer.json", state: state, fresh: false)
  end

  defp without_user(conn) do
    state = Driver.initial({Chat.scenarios(), Chat.databases()})

    user_id = User.generate_id()

    user = User.new(user_id, state)

    token = Token.sign(user_id)

    Storage.put(user)

    conn
    |> put_session(:user_token, token)
    |> render("answer.json", state: state, fresh: true)
  end
end
