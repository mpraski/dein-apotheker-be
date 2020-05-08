defmodule Chat.Validator do
  alias Chat.{Scenario, Answer, Question, Comment, Util, Translator}

  def validate(%Scenario{} = scenario) do
    scenario
    |> validate_all([
      {&validate_entry_point/1, "a scenario needs to start with an existing question"},
      {&validate_exclusion/1, "answer cannot both lead to question and jump to scenario"},
      {&validate_consistency/1,
       "answers need to lead to existing questions withing the scenario"},
      {&validate_cases/1,
       "multiple answer cases need to lead to existing questions withing the scenario"},
      {&validate_default_translation/1,
       "all questions, answers and comments need to be translated in default language (#{
         Translator.default_language()
       })"}
      # {&validate_translation/1, "all questions, answers and comments need to be translated"}
    ])
  end

  defp validate_all(_, []), do: :ok

  defp validate_all(scenario, [{f, error} | checks]) do
    if f.(scenario) do
      scenario |> validate_all(checks)
    else
      {:error, error}
    end
  end

  defp validate_entry_point(%Scenario{
         start: start,
         questions: questions
       }) do
    questions
    |> Enum.map(&Util.pluck(&1, :id))
    |> Enum.member?(start)
  end

  defp validate_exclusion(%Scenario{} = scenario) do
    scenario |> Enum.any?(&validate_exclusion/1) |> Kernel.not()
  end

  defp validate_exclusion(%Answer.Single{leads_to: l, jumps_to: j}), do: l != nil and j != nil
  defp validate_exclusion(%Answer.Multiple{leads_to: l, jumps_to: j}), do: l != nil and j != nil
  defp validate_exclusion(_), do: false

  defp validate_consistency(%Scenario{questions: questions} = scenario) do
    question_ids =
      questions
      |> Enum.map(&Util.pluck(&1, :id))
      |> Util.index()

    scenario |> Enum.all?(&validate_consistency(&1, question_ids))
  end

  defp validate_consistency(%Answer.Single{leads_to: id}, m), do: m |> Util.has_key?(id)
  defp validate_consistency(%Answer.Multiple{leads_to: id}, m), do: m |> Util.has_key?(id)
  defp validate_consistency(%Question.Prompt{leads_to: id}, m), do: m |> Util.has_key?(id)
  defp validate_consistency(_, _), do: true

  defp validate_cases(%Scenario{questions: questions}) do
    questions |> Enum.all?(&validate_cases/1)
  end

  defp validate_cases(%Question.Multiple{decisions: decisions, answers: answers}) do
    answers = answers |> Util.index()
    decisions |> Enum.all?(&validate_cases(&1, answers))
  end

  defp validate_cases(_), do: true

  defp validate_cases(%Answer.Multiple{case: :default}, _), do: true

  defp validate_cases(%Answer.Multiple{case: cases}, t) do
    cases |> Enum.all?(&Map.has_key?(t, &1))
  end

  defp validate_default_translation(%Scenario{translations: ts} = scenario) do
    with l <- Translator.default_language(),
         t <- ts |> Map.get(l) do
      scenario |> Enum.all?(&validate_translation(&1, t))
    end
  end

  defp validate_translation(%Scenario{translations: ts} = scenario) do
    validated =
      for {_, t} <- ts do
        scenario |> Enum.all?(&validate_translation(&1, t))
      end

    Enum.all?(validated)
  end

  defp validate_translation(%Question.Single{id: id}, t), do: t |> Map.has_key?(id)
  defp validate_translation(%Question.Multiple{id: id}, t), do: t |> Map.has_key?(id)
  defp validate_translation(%Question.Prompt{id: id}, t), do: t |> Map.has_key?(id)

  defp validate_translation(%Answer.Single{id: id}, t), do: t |> Map.has_key?(id)

  defp validate_translation(%Answer.Multiple{case: :default}, _), do: true

  defp validate_translation(%Answer.Multiple{case: cases}, t) do
    cases
    |> Enum.map(&Map.has_key?(t, &1))
    |> Enum.all?()
  end

  defp validate_translation(%Comment.Text{content: content}, t), do: t |> Map.has_key?(content)

  defp validate_translation(%Comment.Image{content: c, image: i}, t) do
    [c, i] |> Enum.all?(&Map.has_key?(t, &1))
  end

  defp validate_translation(a, t) when is_binary(a), do: t |> Map.has_key?(a)
end
