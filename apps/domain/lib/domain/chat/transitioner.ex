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

    data = data |> prepare_comments(comments, current)

    {scenarios, question, data}
  end

  def transition({scenarios, question, data}, {:multiple, answers}) do
    [current | _] = scenarios

    %Question.Multiple{
      decisions: decisions,
      load_scenarios: load_scenarios
    } = Chat.question(current, question)

    %Answer.Multiple{
      leads_to: next_question,
      jumps_to: next_scenario,
      loads_scenario: new_scenario,
      comments: comments
    } = decisions |> find_decision(answers)

    {scenarios, question} =
      next(
        next_question,
        next_scenario,
        new_scenario,
        scenarios
      )

    scenarios =
      if load_scenarios do
        answers |> Enum.reduce(scenarios, &load_scenario(&2, &1))
      else
        scenarios
      end

    data = data |> prepare_comments(comments, current)

    {scenarios, question, data}
  end

  def transition({scenarios, question, data}, {:prompt, answer}) do
    [current | _] = scenarios

    %Question.Prompt{
      id: id,
      leads_to: next_question,
      jumps_to: next_scenario,
      loads_scenario: new_scenario,
      comments: comments
    } = Chat.question(current, question)

    {scenarios, question} =
      next(
        next_question,
        next_scenario,
        new_scenario,
        scenarios
      )

    data =
      data
      |> prepare_comments(comments, current)
      |> Map.put(id, answer)

    {scenarios, question, data}
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

          # If we jump to terminal, then we
          # discard all pending scenarios.
          # Baby, it's the end of the line!
          if next_scenario == @terminal_scenario do
            {[next_scenario], start}
          else
            [_ | rest] = scenarios
            {[next_scenario | rest], start}
          end

        true ->
          case scenarios do
            [_, previous | rest] ->
              %Scenario{start: start} = Chat.scenario(previous)
              {[previous | rest], start}

            [@terminal_scenario] ->
              {[], nil}

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

  defp prepare_comments(data, comments, scenario) do
    data
    |> Map.put(:comments, comments)
    |> Map.put(:comments_scenario, scenario)
  end

  defp find_decision(decisions, answer) do
    with default <- decisions |> Enum.find(nil, &(&1.case == :default)) do
      decisions |> Enum.find(default, &Util.equal(&1.case, answer))
    end
  end

  defp load_scenario(scenarios, nil), do: scenarios
  defp load_scenario(scenarios, scenario), do: scenarios ++ [scenario]
end
