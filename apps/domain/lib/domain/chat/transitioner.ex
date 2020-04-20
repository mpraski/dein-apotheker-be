defmodule Chat.Transitioner do
  alias Chat.{Scenario, Question, Answer, Util}

  @initial_scenario "initial"
  @terminal_scenario "terminal"

  def transition({scenarios, question, data}, {:single, answer}) do
    [current | _] = scenarios

    %Question.Single{
      answers: answers
    } = Chat.question(current, question)

    %Answer.Single{
      leads_to: next_question,
      jumps_to: next_scenario,
      loads_scenario: new_scenario,
      comments: comments
    } = answers |> Enum.find(nil, &(&1.id == answer))

    {scenarios, question} =
      next(
        next_question,
        next_scenario,
        new_scenario,
        scenarios
      )

    data = data |> Map.put(:comments, comments)

    {scenarios, question, data}
  end

  def transition({scenarios, question, data}, {:multiple, answer}) do
    [current | _] = scenarios

    %Question.Multiple{
      decisions: decisions
    } = Chat.question(current, question)

    %Answer.Multiple{
      leads_to: next_question,
      jumps_to: next_scenario,
      loads_scenario: new_scenario,
      comments: comments
    } = decisions |> find_decision(answer)

    {scenarios, question} =
      next(
        next_question,
        next_scenario,
        new_scenario,
        scenarios
      )

    data = data |> Map.put(:comments, comments)

    {scenarios, question, data}
  end

  def transition({scenarios, question, data}, {:prompt, answer}) do
    [current | rest] = scenarios

    %Question.Prompt{
      id: id,
      leads_to: next_question
    } = Chat.question(current, question)

    scenarios = if next_question, do: scenarios, else: rest
    data = data |> Map.put(id, answer)

    {scenarios, next_question, data}
  end

  def transition do
    %Scenario{start: start} = Chat.scenario(@initial_scenario)
    {[@initial_scenario], start, %{}}
  end

  defp next(next_question, next_scenario, new_scenario, scenarios) do
    {scenarios, question} =
      cond do
        next_question ->
          {scenarios, next_question}

        next_scenario ->
          %Scenario{start: start} = Chat.scenario(next_scenario)
          [_ | rest] = scenarios

          {[next_scenario | rest], start}

        true ->
          case scenarios do
            [_, previous | rest] ->
              %Scenario{start: start} = Chat.scenario(previous)
              {[previous | rest], start}

            [_] ->
              %Scenario{start: start} = Chat.scenario(@terminal_scenario)
              {[@terminal_scenario], start}

            [] ->
              raise "Should not reach here"
          end
      end

    scenarios = scenarios |> load_scenario(new_scenario)

    {scenarios, question}
  end

  defp find_decision(decisions, answer) do
    default = decisions |> Enum.find(nil, &(&1.case == :default))
    decisions |> Enum.find(default, &Util.equal(&1.case, answer))
  end

  defp load_scenario(scenarios, nil), do: scenarios
  defp load_scenario(scenarios, scenario), do: scenarios ++ [scenario]
end
