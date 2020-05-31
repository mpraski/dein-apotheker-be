defmodule Chat.Journey.Exporter do
  alias Chat.Journey.Record

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

  defp export_answers(_, []), do: :ok

  defp export_answers(token, [
         {
           {scenarios, question, data},
           answer,
           timestamp
         }
         | answers
       ]) do
    {answer_type, answer_value} = case answer do
        nil -> {"none", "<start>"}
        {type, value} -> {Atom.to_string(type), format_answer(value)}
    end

    case %Record{
           token: token,
           answer: answer_value,
           answer_type: answer_type,
           question: question,
           scenario: List.first(scenarios),
           data: data,
           when: timestamp
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
