defmodule Chat.Transitioner do
  alias Chat.{Scenario, Question, Answer, Util}

  @initial_scenario "initial"
  @terminal_scenario "terminal"
  @defaults %{
    next_question: nil,
    next_scenario: nil,
    new_scenario: nil,
    new_scenarios: nil,
    load_scenarios: nil
  }

  def transition({[current | _], question, _} = context, {:single, answer}) do
    %Question.Single{
      answers: answers
    } = Chat.question(current, question)

    %Answer.Single{
      leads_to: next_question,
      jumps_to: next_scenario,
      loads_scenario: new_scenario,
      comments: comments
    } = answers |> Enum.find(nil, &(&1.id == answer))

    context
    |> core(
      next_question: next_question,
      next_scenario: next_scenario,
      new_scenario: new_scenario
    )
    |> put_comments(comments, current)
    |> load_messages()
  end

  def transition({[current | _], question, _} = context, {:multiple, answers}) do
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

    context
    |> core(
      next_question: next_question,
      next_scenario: next_scenario,
      new_scenario: new_scenario,
      new_scenarios: answers,
      load_scenarios: load_scenarios
    )
    |> put_comments(comments, current)
    |> load_messages()
  end

  def transition({[current | _], question, _} = context, {:prompt, answer}) do
    %Question.Prompt{
      leads_to: next_question,
      jumps_to: next_scenario,
      loads_scenario: new_scenario,
      comments: comments
    } = Chat.question(current, question)

    context
    |> core(
      next_question: next_question,
      next_scenario: next_scenario,
      new_scenario: new_scenario
    )
    |> put_comments(comments, current)
    |> put_free_text(answer)
    |> load_messages()
  end

  def transition do
    %Scenario{start: start} = Chat.scenario(@initial_scenario)
    {[@initial_scenario], start, %{}} |> load_messages()
  end

  def load_messages({[], _, _} = context), do: context

  def load_messages({scenarios, question, data} = context) do
    [current | _] = scenarios

    case Chat.question(current, question) do
      %Question.Message{
        leads_to: leads_to,
        comments: comments
      } ->
        with comments <- comments |> Enum.map(&{&1, current}),
             data <- data |> Map.update(:comments, [], &(comments ++ &1)) do
          {scenarios, leads_to, data} |> load_messages()
        end

      _ ->
        context
    end
  end

  defp core({scenarios, _, data}, opts \\ []) do
    opts = opts |> Enum.into(@defaults)

    {scenarios, question} =
      cond do
        opts.next_question ->
          {scenarios, opts.next_question}

        opts.next_scenario ->
          %Scenario{start: start} = Chat.scenario(opts.next_scenario)

          # If we jump to terminal, then we
          # discard all pending scenarios.
          # Baby, it's the end of the line!
          if opts.next_scenario == @terminal_scenario do
            {[opts.next_scenario], start}
          else
            [_ | rest] = scenarios
            {[opts.next_scenario | rest], start}
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

    scenarios =
      if opts.new_scenario do
        scenarios ++ [opts.new_scenario]
      else
        scenarios
      end

    scenarios =
      if opts.load_scenarios do
        opts.new_scenarios |> Enum.reduce(scenarios, &(&2 ++ [&1]))
      else
        scenarios
      end

    {scenarios, question, data}
  end

  defp put_comments({scenarios, question, data}, comments, current) do
    data =
      with comments <- comments |> Enum.map(&{&1, current}) do
        data |> Map.put(:comments, comments)
      end

    {scenarios, question, data}
  end

  defp put_free_text({scenarios, question, data}, answer) do
    {scenarios, question, data |> Map.put(question, answer)}
  end

  defp find_decision(decisions, answer) do
    with default <- decisions |> Enum.find(nil, &(&1.case == :default)) do
      decisions |> Enum.find(default, &Util.equal(&1.case, answer))
    end
  end
end
