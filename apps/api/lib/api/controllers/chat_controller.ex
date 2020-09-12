defmodule Api.ChatController do
  use Api, :controller

  alias Api.Plugs.{FromContext, RequireToken}
  alias Api.FallbackController

  @question_types ~w[single multiple prompt]

  plug(RequireToken)
  plug(FromContext)

  action_fallback(FallbackController)

  @question_types |> Enum.each(&String.to_existing_atom/1)

  def answer(conn, %{
        "type" => type,
        "value" => value
      })
      when type in @question_types do
    if conn.assigns.has_context? do
      with token <- conn.assigns.token,
           context <- conn.assigns.context,
           answer <- {String.to_existing_atom(type), value} do
        conn |> render("answer.json", context: nil)
      end
    else
      {:error, 400, "Badly formed request"}
    end
  end

  def answer(conn, _params) do
    if conn.assigns.has_context? do
      with token <- conn.assigns.token do
        conn |> render("answer.json", context: nil)
      end
    else
      {:error, 400, "Badly formed request"}
    end
  end
end
