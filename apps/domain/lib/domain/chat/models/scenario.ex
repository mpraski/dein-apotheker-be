defmodule Chat.Scenario do
  @enforce_keys [:id, :start, :questions, :translations]

  defstruct(
    id: nil,
    start: nil,
    questions: [],
    translations: %{}
  )
end

defimpl Enumerable, for: Chat.Scenario do
  alias Chat.{Scenario, Question, Answer, Comment}

  def count(_), do: {:error, __MODULE__}

  def member?(_, _), do: {:error, __MODULE__}

  def slice(_), do: {:error, __MODULE__}

  def reduce(%Scenario{questions: q}, acc, fun) do
    reduce_scenario(q, acc, fun)
  end

  defp reduce_scenario(_, {:halt, acc}, _fun), do: {:halted, acc}

  defp reduce_scenario(scenario, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce_scenario(scenario, &1, fun)}

  defp reduce_scenario([], {:cont, acc}, _fun), do: {:done, acc}

  defp reduce_scenario([%Question.Single{answers: answers} = q | t], {:cont, acc}, fun) do
    reduce_scenario(answers ++ t, fun.(q, acc), fun)
  end

  defp reduce_scenario(
         [
           %Question.Multiple{
             answers: answers,
             decisions: decisions
           } = q
           | t
         ],
         {:cont, acc},
         fun
       ) do
    reduce_scenario(answers ++ decisions ++ t, fun.(q, acc), fun)
  end

  defp reduce_scenario([%Question.Prompt{} = q | t], {:cont, acc}, fun) do
    reduce_scenario(t, fun.(q, acc), fun)
  end

  defp reduce_scenario([%Answer.Single{comments: comments} = a | t], {:cont, acc}, fun) do
    rest =
      case comments do
        nil -> t
        comments -> comments ++ t
      end

    reduce_scenario(rest, fun.(a, acc), fun)
  end

  defp reduce_scenario([%Answer.Multiple{comments: comments} = a | t], {:cont, acc}, fun) do
    rest =
      case comments do
        nil -> t
        comments -> comments ++ t
      end

    reduce_scenario(rest, fun.(a, acc), fun)
  end

  defp reduce_scenario([%Comment.Text{} = c | t], {:cont, acc}, fun) do
    reduce_scenario(t, fun.(c, acc), fun)
  end

  defp reduce_scenario([%Comment.Image{} = c | t], {:cont, acc}, fun) do
    reduce_scenario(t, fun.(c, acc), fun)
  end

  defp reduce_scenario([a | t], {:cont, acc}, fun) when is_binary(a) do
    reduce_scenario(t, fun.(a, acc), fun)
  end
end
