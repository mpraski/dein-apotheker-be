defmodule Chat.Validator do
  alias Chat.{Answer, Question, Comment}

  def validate_questions(questions) do
    unless validate_exclusion(questions) do
      {:error, "answer cannot both lead to question and jump to scenario"}
    end

    unless validate_consistency(questions) do
      {:error, "answers need to lead to existing questions withing the scenario"}
    end

    :ok
  end

  def validate_translations(questions, translation) do
    unless validate_translation(questions, translation) do
      {:error, "all questions, answer and comments must be translated"}
    end

    :ok
  end

  defp validate_exclusion(questions) when is_list(questions) do
    questions |> Enum.any?(&validate_exclusion/1)
  end

  defp validate_exclusion(%Question.Single{answers: answers}) do
    answers |> Enum.any?(fn %Answer.Single{leads_to: l, jumps_to: j} -> l != nil and j != nil end)
  end

  defp validate_exclusion(%Question.Multiple{decisions: decisions}) do
    decisions
    |> Enum.any?(fn %Answer.Multiple{leads_to: l, jumps_to: j} -> l != nil and j != nil end)
  end

  defp validate_exclusion(%Question.Prompt{}), do: true

  defp validate_consistency(questions) when is_list(questions) do
    question_ids = questions |> Enum.map(&extract_id/1) |> index()
    questions |> Enum.all?(&validate_consistency(&1, question_ids))
  end

  defp validate_consistency(%Question.Single{answers: answers}, mapped) do
    answers |> Enum.all?(fn %Answer.Single{leads_to: id} -> Map.has_key?(mapped, id) end)
  end

  defp validate_consistency(%Question.Multiple{decisions: decisions}, mapped) do
    decisions |> Enum.all?(fn %Answer.Multiple{leads_to: id} -> Map.has_key?(mapped, id) end)
  end

  defp validate_consistency(%Question.Prompt{leads_to: id}, mapped) do
    Map.has_key?(mapped, id)
  end

  defp validate_translation(nil, _), do: true

  defp validate_translation([], _), do: true

  defp validate_translation(%Question.Single{id: id, answers: answers} = q, t) do
    has_id = t |> Map.has_key?(id)
    has_answers = answers |> Enum.all?(fn %Answer.Single{id: id} -> t |> Map.has_key?(id) end)
    has_comments = q |> Map.get(:comments) |> validate_translation(t)

    Enum.all?([has_id, has_answers, has_comments])
  end

  defp validate_translation(
         %Question.Multiple{
           answers: answers
         } = q,
         t
       ) do
    has_answers = answers |> Enum.all?(&Map.has_key?(t, &1))
    has_comments = q |> Map.get(:comments) |> validate_translation(t)

    Enum.all?([has_answers, has_comments])
  end

  defp validate_translation(%Question.Prompt{id: id}, t) do
    t |> Map.has_key?(id)
  end

  defp validate_translation(%Answer.Single{id: id} = q, t) do
    has_id = t |> Map.has_key?(id)
    has_comments = q |> Map.get(:comments) |> validate_translation(t)

    Enum.all?([has_id, has_comments])
  end

  defp validate_translation(%Answer.Multiple{} = q, t) do
    q |> Map.get(:comments) |> validate_translation(t)
  end

  defp validate_translation([%Comment.Text{content: content} | rest], t) do
    has_content = t |> Map.has_key?(content)
    has_rest = rest |> validate_translation(t)

    Enum.all?([has_content, has_rest])
  end

  defp validate_translation([%Comment.Image{content: content, image: image} | rest], t) do
    has_content = t |> Map.has_key?(content)
    has_image = t |> Map.has_key?(image)
    has_rest = rest |> validate_translation(t)

    Enum.all?([has_content, has_image, has_rest])
  end

  defp validate_translation(questions, translations) do
    questions |> Enum.all?(&validate_translation(&1, translations))
  end

  defp index(items) do
    items |> Enum.map(fn i -> {i, nil} end) |> Map.new()
  end

  defp extract_id(%Question.Single{id: id}), do: id
  defp extract_id(%Question.Multiple{id: id}), do: id
  defp extract_id(%Question.Prompt{id: id}), do: id
end
