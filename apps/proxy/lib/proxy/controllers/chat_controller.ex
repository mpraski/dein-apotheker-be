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
            "state" => "new",
            "answer" => nil
          }
        } = conn,
        _params
      ) do
    session = conn.assigns.session

    state = Driver.initial()

    session |> Session.add(state) |> Store.put()

    conn |> render("answer.json", state: state)
  end

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

    case session |> Session.fetch(state) do
      {:ok, state} ->
        state = state |> Driver.next(answer)

        session |> Session.add(state) |> Store.put()

        IO.inspect state

        conn |> render("answer.json", state: state)

      :error ->
        {:error, 400}
    end
  end

  def answer(_conn, _params) do
    {:error, 400}
  end
end
