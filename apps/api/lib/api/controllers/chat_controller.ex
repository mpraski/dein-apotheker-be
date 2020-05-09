defmodule Api.ChatController do
  use Api, :controller

  alias Chat.{Transitioner, Translator, Recorder}
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
      with token <- conn.assigns.token,
           context <- conn.assigns.context,
           answer <- {String.to_atom(type), value},
           new_context <- Transitioner.transition(context, answer),
           :ok <- Recorder.record(token, context, answer) do
        conn |> render("answer.json", context: new_context)
      end
    else
      {:error, 400, "Badly formed request"}
    end
  end

  def answer(conn, _params) do
    if conn.assigns.has_context? do
      with token <- conn.assigns.token,
           context <- Transitioner.transition(),
           :ok <- Recorder.record(token, context, nil) do
        conn |> render("answer.json", context: context)
      end
    else
      {:error, 400, "Badly formed request"}
    end
  end

  def languages(conn, _params) do
    conn
    |> render("languages.json",
      languages: Translator.languages(),
      default: Translator.default_language()
    )
  end
end
