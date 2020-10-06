defmodule Proxy.ChatController do
  use Proxy, :controller

  alias Plug.Conn
  alias Proxy.Session
  alias Proxy.Session.Store
  alias Proxy.FallbackController
  alias Chat.Driver

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
    session = conn.assigns.session

    if Session.fresh(session) do
      conn |> render("answer.json", state: Session.current_state(session), fresh: true)
    else
      %Session{
        user_id: user_id,
        states: states
      } = session

      case Map.fetch(states, state) do
        {:ok, state} ->
          context = {Chat.scenarios(), Chat.databases()}

          state = state |> Driver.next(context, answer)

          user_id |> Store.add(state)

          conn |> render("answer.json", state: state, fresh: false)

        :error ->
          {:error, 400, "bad request"}
      end
    end
  end

  def answer(_conn, _params) do
    {:error, 400, "Badly formed request"}
  end
end
