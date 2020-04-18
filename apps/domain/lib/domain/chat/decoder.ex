defmodule Chat.Decoder do
  alias Chat.{Question, Answer, Comment}

  def decode_questions(%{"questions" => questions}) when is_map(questions) do
    questions |> Enum.map(&decode_question/1)
  end

  defp decode_question(
         {id,
          %{
            "type" => type
          } = question}
       )
       when type in ~w[single multiple prompt] do
    answers =
      case Map.fetch(question, "answers") do
        {:ok, a} -> a |> Enum.map(&decode_answer/1)
        _ -> []
      end

    %Question{
      id: String.to_atom(id),
      type: String.to_atom(type),
      answers: answers
    }
  end

  defp decode_answer({id, props}) do
    %Answer{id: String.to_atom(id)} |> decode_answer(props |> to_keywords())
  end

  defp decode_answer(%Answer{} = a, [{:leads_to, leads_to} | rest]) do
    %Answer{a | leads_to: String.to_atom(leads_to)} |> decode_answer(rest)
  end

  defp decode_answer(%Answer{} = a, [{:jumps_to, jumps_to} | rest]) do
    %Answer{a | jumps_to: String.to_atom(jumps_to)} |> decode_answer(rest)
  end

  defp decode_answer(%Answer{} = a, [{:loads_scenario, loads_scenario} | rest]) do
    %Answer{a | loads_scenario: String.to_atom(loads_scenario)} |> decode_answer(rest)
  end

  defp decode_answer(%Answer{} = a, [{:comments, comments} | rest]) do
    %Answer{a | comments: comments |> Enum.map(&decode_comment/1)} |> decode_answer(rest)
  end

  defp decode_answer(%Answer{} = a, [{:terminal, terminal} | rest]) do
    %Answer{a | terminal: terminal} |> decode_answer(rest)
  end

  defp decode_answer(%Answer{} = a, []), do: a

  defp decode_comment(%{"type" => "text", "content" => content}) do
    %Comment{
      type: :text,
      content: String.to_atom(content)
    }
  end

  defp decode_comment(%{"type" => "image", "content" => content, "image" => image}) do
    %Comment{
      type: :image,
      content: String.to_atom(content),
      image: String.to_atom(image)
    }
  end

  defp to_keywords(m) when is_map(m) do
    m |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end

  def validate_questions(questions) do
    if !validate_exclusion(questions) do
      {:error, "answer cannot both lead to question and jump to scenario"}
    end

    if !validate_consistency(questions) do
      {:error, "answers need to lead to existing questions withing the scenario"}
    end

    :ok
  end

  defp validate_exclusion(questions) when is_list(questions) do
    questions |> Enum.any?(&validate_exclusion/1)
  end

  defp validate_exclusion(%Question{answers: answers}) do
    answers |> Enum.any?(fn %Answer{leads_to: l, jumps_to: j} -> l != nil and j != nil end)
  end

  defp validate_consistency(questions) when is_list(questions) do
    question_ids =
      questions
      |> Enum.map(fn %Question{id: id} -> id end)
      |> Enum.map(fn id -> {id, nil} end)
      |> Map.new()

    questions |> Enum.all?(&validate_consistency(&1, question_ids))
  end

  defp validate_consistency(%Question{answers: answers}, mapped) do
    answers |> Enum.all?(fn %Answer{id: id} -> Map.has_key?(mapped, id) end)
  end

  def map_questions(questions) do
    questions |> Enum.map(fn %Question{id: id} = q -> {id, q} end) |> Map.new()
  end

  def decode_translations(translations) when is_map(translations) do
    translations |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end) |> Map.new()
  end
end
