defmodule Chat.Transitioner do
  alias Chat.{Scenario, Answer, Comment}

  @general_scenario :general

  # (_, _) -> (initial context, initial question) | nil
  def transition({[], _, _}, _) do
    %Scenario{start: start, questions: questions} = Chat.scenario(@general_scenario)

    {
      {
        [@general_scenario],
        start,
        %{}
      },
      questions |> Map.get(start)
    }
  end

  # (context, answer) -> (context, question) | nil
  def transition({scenarios, question, data}, answer) do
    current_scenario = scenarios |> List.last()
    current_question = Chat.question(current_scenario, question)
  end
end
