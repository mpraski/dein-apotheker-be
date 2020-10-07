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
    %Session{
      states: states
    } = session = conn.assigns.session

    case Map.fetch(states, state) do
      {:ok, state} ->
        context = {Chat.scenarios(), Chat.databases()}

        state = state |> Driver.next(context, answer)

        Store.put(Session.add(session, state))

        conn |> render("answer.json", state: state, fresh: false)

      :error ->
        {:error, 400, "bad request"}
    end
  end

  def answer(
        %Conn{
          body_params: %{
            "state" => "new"
          }
        } = conn,
        _params
      ) do
    session = conn.assigns.session

    state = Driver.initial({Chat.scenarios(), Chat.databases()})

    Store.put(Session.add(session, state))

    conn |> render("answer.json", state: state, fresh: true)
  end

  def answer(_conn, _params) do
    {:error, 400, "bad request"}
  end
end
