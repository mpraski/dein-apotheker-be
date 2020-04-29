defmodule Api.ChatController do
  use Api, :controller

  alias Chat.{Transitioner, Translator}
  alias Api.Plugs.{FromContext, RequireToken}
  alias Api.FallbackController

  @question_types ~w[single multiple prompt]

  plug(RequireToken)
  plug(FromContext)

  action_fallback(FallbackController)

  def answer(conn, %{
        "type" => type,
        "value" => value
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

  def languages(conn, _params) do
    conn |> render("languages.json", languages: Translator.languages())
  end
end
