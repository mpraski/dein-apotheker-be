defmodule Api.ChatController do
  use Api, :controller

  alias Chat.Transitioner
  alias Api.Plugs.FromContext
  alias Api.FallbackController

  @question_types ~w[single multiple prompt]

  plug(FromContext)

  action_fallback(FallbackController)

  def answer(conn, %{
        "answer" => %{
          "type" => type,
          "value" => value
        }
      })
      when type in @question_types do
    if conn.assigns.has_context? do
      with context <- conn.assigns.context,
           answer <- {String.to_atom(type), value},
           new_context <- Transitioner.transition(context, answer) do
        conn |> render("answer.json", context: new_context)
      end
    else
      {:error, 400, "Badly formed request"}
    end
  end

  def answer(conn, _params) do
    if conn.assigns.has_context? do
      conn |> render("answer.json", context: Transitioner.transition())
    else
      {:error, 400, "Badly formed request"}
    end
  end

  def token(conn, _params) do
    with token <- UUID.uuid4() do
      conn |> render("token.json", token: token)
    end
  end
end
