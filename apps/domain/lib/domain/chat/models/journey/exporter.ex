defmodule Chat.Journey.Exporter do
  alias Chat.Journey.Record
  require Logger

  @start {"none", "<start>"}

  def export(history) do
    results =
      history
      |> Enum.map(fn {token, answers} -> export_answers(token, answers) end)
      |> Enum.filter(fn
        :ok -> false
        {:error, _} -> true
      end)

    case results do
      [] -> :ok
      [e | _] -> e
    end
  end

  def export_log(history) do
    history
    |> Enum.each(fn {token, answers} ->
      Logger.debug("New steps for token #{token}:")
      answers |> Enum.each(&Logger.debug(inspect(&1)))
    end)

    :ok
  end

  defp export_answers(_, []), do: :ok

  defp export_answers(token, [
         {
           {scenarios, question, data},
           answer,
           answered_at
         }
         | answers
       ]) do
    {answer_type, answer_value} =
      case answer do
        nil -> @start
        {type, value} -> {Atom.to_string(type), format_answer(value)}
      end

    case %Record{
           token: token,
           answer: answer_value,
           answer_type: answer_type,
           question: question,
           scenario: List.first(scenarios),
           data: data,
           answered_at: answered_at
         }
         |> Record.changeset(%{})
         |> Domain.Repo.insert() do
      {:ok, _} -> export_answers(token, answers)
      {:error, error} -> {:error, error}
    end
  end

  defp format_answer(a) when is_binary(a), do: a

  defp format_answer(a) when is_list(a) do
    a |> Enum.join(",")
  end
end
