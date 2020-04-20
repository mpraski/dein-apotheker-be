defmodule Api.ChatController do
  use Api, :controller

  alias Chat.{Util, Transitioner}

  @question_types ~w[single multiple prompt]

  def index(conn, _params) do
    scenario = Chat.scenario(:initial)
    render(conn, "index.json", scenario: scenario)
  end

  def create(conn, %{
        "context" => %{
          "scenarios" => scenarios,
          "question" => question,
          "data" => data
        },
        "answer" => %{
          "type" => type,
          "value" => value
        }
      })
      when type in @question_types do
    context = {scenarios, question, data}
    answer = {String.to_atom(type), value}
    new_context = Transitioner.transition(context, answer)
    render(conn, "create.json", context: new_context)
  end

  def create(conn, _) do
    render(conn, "create.json", context: Transitioner.transition())
  end
end
