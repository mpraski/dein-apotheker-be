defmodule Api.ChatController do
  use Api, :controller

  alias Api.Plugs.{FromState, RequireToken}
  alias Api.FallbackController

  alias Chat.Driver

  plug(RequireToken)
  plug(FromState)

  action_fallback(FallbackController)

  def answer(conn, %{
        "type" => type,
        "value" => value
      }) do
    if conn.assigns.has_state? do
      state = conn.assigns.state
      answer = {String.to_existing_atom(type), value}
      data = {Chat.scenarios(), Chat.databases()}

      state =
        state
        |> Driver.next(data, answer)

      conn |> render("answer.json", state: state)
    else
      {:error, 400, "Badly formed request"}
    end
  end

  def answer(conn, %{}) do
    if conn.assigns.has_state? do
      state = {Chat.scenarios(), Chat.databases()} |> Driver.initial()

      conn |> render("answer.json", state: state)
    else
      {:error, 400, "Badly formed request"}
    end
  end
end
