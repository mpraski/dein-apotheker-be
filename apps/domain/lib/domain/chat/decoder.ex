defmodule Chat.Decoder do
  alias Chat.{Question, Answer, Comment, Util}

  def decode_start(%{"start" => start}), do: String.to_atom(start)

  def decode_questions(%{"questions" => questions}) do
    questions |> Enum.map(&decode_question/1)
  end

  def decode_translations(translations) do
    translations |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end) |> Map.new()
  end

  defp decode_question(
         {id,
          %{
            "type" => "single",
            "answers" => answers
          }}
       ) do
    %Question.Single{
      id: String.to_atom(id),
      answers: answers |> Enum.map(&decode_answer_single/1)
    }
  end

  defp decode_question(
         {id,
          %{
            "type" => "multiple",
            "answers" => answers,
            "decisions" => decisions
          }}
       )
       when is_list(answers) and is_list(decisions) do
    %Question.Multiple{
      id: String.to_atom(id),
      answers: answers |> Enum.map(&String.to_atom/1),
      decisions: decisions |> Enum.map(&decode_answer_multiple/1)
    }
  end

  defp decode_question(
         {id,
          %{
            "type" => "prompt"
          } = question}
       ) do
    leads_to =
      case question |> Map.fetch("leads_to") do
        {:ok, leads_to} -> String.to_atom(leads_to)
        _ -> nil
      end

    %Question.Prompt{
      id: String.to_atom(id),
      leads_to: leads_to
    }
  end

  defp decode_answer_single({id, props}) do
    %Answer.Single{id: String.to_atom(id)} |> decode_answer_single(props |> Util.to_keywords())
  end

  defp decode_answer_single(%Answer.Single{} = a, [{:leads_to, leads_to} | rest]) do
    %Answer.Single{a | leads_to: String.to_atom(leads_to)} |> decode_answer_single(rest)
  end

  defp decode_answer_single(%Answer.Single{} = a, [{:jumps_to, jumps_to} | rest]) do
    %Answer.Single{a | jumps_to: String.to_atom(jumps_to)} |> decode_answer_single(rest)
  end

  defp decode_answer_single(%Answer.Single{} = a, [{:loads_scenario, loads_scenario} | rest]) do
    load_scenario = String.to_atom(loads_scenario)
    %Answer.Single{a | loads_scenario: load_scenario} |> decode_answer_single(rest)
  end

  defp decode_answer_single(%Answer.Single{} = a, [{:comments, comments} | rest]) do
    comments = comments |> Enum.map(&decode_comment/1)
    %Answer.Single{a | comments: comments} |> decode_answer_single(rest)
  end

  defp decode_answer_single(%Answer.Single{} = a, []), do: a

  defp decode_answer_multiple(decision) when is_map(decision) do
    %Answer.Multiple{} |> decode_answer_multiple(decision |> Util.to_keywords())
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:case, "default"} | rest]) do
    %Answer.Multiple{d | case: :default} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:case, cases} | rest]) do
    cases = cases |> Enum.map(&String.to_atom/1)
    %Answer.Multiple{d | case: cases} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:leads_to, leads_to} | rest]) do
    %Answer.Multiple{d | leads_to: String.to_atom(leads_to)} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:jumps_to, jumps_to} | rest]) do
    %Answer.Multiple{d | jumps_to: String.to_atom(jumps_to)} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:loads_scenario, loads_scenario} | rest]) do
    loads_scenario = String.to_atom(loads_scenario)
    %Answer.Multiple{d | loads_scenario: loads_scenario} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:comments, comments} | rest]) do
    comments = comments |> Enum.map(&decode_comment/1)
    %Answer.Multiple{d | comments: comments} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, []), do: d

  defp decode_comment(%{"type" => "text", "content" => content}) do
    %Comment.Text{
      content: String.to_atom(content)
    }
  end

  defp decode_comment(%{"type" => "image", "content" => content, "image" => image}) do
    %Comment.Image{
      content: String.to_atom(content),
      image: String.to_atom(image)
    }
  end
end
