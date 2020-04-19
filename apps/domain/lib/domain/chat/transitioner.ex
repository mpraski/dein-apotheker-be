defmodule Chat.Transitioner do
  alias Chat.{Scenario, Question, Answer}

  @general_scenario :general

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

  def transition({scenarios, question, data}, {:single, answer}) do
    [current | rest] = scenarios

    %Question.Single{answers: a} = Chat.question(current, question)

    %Answer.Single{
      leads_to: next_question,
      jumps_to: next_scenario,
      loads_scenario: new_scenario
    } = a |> Enum.find(nil, &(&1.id == answer))

    {scenario, question} =
      cond do
        next_question != nil ->
          {
            current,
            Chat.question(current, next_question)
          }

        next_scenario != nil ->
          %Scenario{start: start} = Chat.scenario(next_scenario)

          {
            next_scenario,
            Chat.question(next_scenario, start)
          }
      end

    scenarios = [scenario | rest |> load_scenario(new_scenario)]

    {scenarios, question, data}
  end

  def transition({scenarios, question, data}, {:prompt, answer}) do
    [current | _] = scenarios

    %Question.Prompt{id: id, leads_to: next_question} = Chat.question(current, question)

    data = data |> Map.put(id, answer)

    next_question =
      if next_question != nil do
        Chat.question(current, next_question)
      end

    {scenarios, next_question, data}
  end

  defp load_scenario(scenarios, nil), do: scenarios
  defp load_scenario(scenarios, scenario), do: scenarios ++ [scenario]
end
