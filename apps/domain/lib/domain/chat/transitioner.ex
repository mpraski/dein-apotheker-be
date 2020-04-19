defmodule Chat.Transitioner do
  alias Chat.{Scenario, Question, Answer, Util}

  @initial_scenario :general
  @terminal_scenario :terminal

  def transition({[], _, _}, _) do
    %Scenario{start: start, questions: questions} = Chat.scenario(@initial_scenario)

    {
      {
        [@initial_scenario],
        start,
        %{}
      },
      questions |> Map.get(start)
    }
  end

  def transition({scenarios, question, data}, {:single, answer}) do
    [current | rest] = scenarios

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
      cond do
        next_question ->
          {
            [current | rest],
            next_question
          }

        next_scenario ->
          %Scenario{start: start} = Chat.scenario(next_scenario)

          {
            [next_scenario | rest],
            start
          }

        true ->
          [previous_scenario | _] = rest

          %Scenario{start: start} = Chat.scenario(previous_scenario)

          {
            rest,
            start
          }
      end

    scenarios = scenarios |> load_scenario(new_scenario)
    data = data |> Map.put(:comments, comments)

    {scenarios, question, data}
  end

  def transition({scenarios, question, data}, {:multiple, answer}) do
    [current | rest] = scenarios

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
      cond do
        next_question ->
          {
            [current | rest],
            next_question
          }

        next_scenario ->
          %Scenario{start: start} = Chat.scenario(next_scenario)

          {
            [next_scenario | rest],
            start
          }

        # To-Do what when this is the last scenario?
        true ->
          [previous_scenario | _] = rest

          %Scenario{start: start} = Chat.scenario(previous_scenario)

          {
            rest,
            start
          }
      end

    scenarios = scenarios |> load_scenario(new_scenario)
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

  def find_decision(decisions, answer) do
    default = decisions |> Enum.find(nil, &(&1.case == :default))
    decisions |> Enum.find(default, &Util.equal(&1.case, answer))
  end

  defp load_scenario(scenarios, nil), do: scenarios
  defp load_scenario(scenarios, scenario), do: scenarios ++ [scenario]
end
