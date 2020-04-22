defmodule Api.ChatController do
  use Api, :controller

  alias Chat.Transitioner

  @question_types ~w[single multiple prompt]

  plug(Api.Plugs.FromContext)

  def create(conn, %{
        "answer" => %{
          "type" => type,
          "value" => value
        }
      })
      when type in @question_types do
    if conn.assigns.has_context? do
      context = conn.assigns.context
      answer = {String.to_atom(type), value}
      conn |> render("create.json", context: Transitioner.transition(context, answer))
    else
      conn
      |> put_flash(:error, "You need to sign in or sign up before continuing.")
      |> halt()
    end
  end

  def create(conn, _) do
    render(conn, "create.json", context: Transitioner.transition())
  end
end
