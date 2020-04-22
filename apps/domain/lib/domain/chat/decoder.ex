defmodule Chat.Decoder do
  alias Chat.{Question, Answer, Comment, Util}

  def decode_start(%{"start" => start}), do: start

  def decode_questions(%{"questions" => questions}) do
    questions |> Enum.map(&decode_question/1)
  end

  defp decode_question(
         {id,
          %{
            "type" => "single",
            "answers" => answers
          }}
       ) do
    answers = answers |> Enum.map(&decode_answer_single/1)

    %Question.Single{
      id: id,
      answers: answers
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
    decisions = decisions |> Enum.map(&decode_answer_multiple/1)

    %Question.Multiple{
      id: id,
      answers: answers,
      decisions: decisions
    }
  end

  defp decode_question({
         id,
         %{
           "type" => "prompt"
         } = question
       }) do
    {_, question} = question |> Map.pop("type")

    %Question.Prompt{id: id} |> decode_question_prompt(Util.to_keywords(question))
  end

  defp decode_question_prompt(%Question.Prompt{} = q, [{:leads_to, leads_to} | rest]) do
    %Question.Prompt{q | leads_to: leads_to} |> decode_question_prompt(rest)
  end

  defp decode_question_prompt(%Question.Prompt{} = q, [{:jumps_to, jumps_to} | rest]) do
    %Question.Prompt{q | jumps_to: jumps_to} |> decode_question_prompt(rest)
  end

  defp decode_question_prompt(%Question.Prompt{} = q, [{:loads_scenario, loads_scenario} | rest]) do
    %Question.Prompt{q | loads_scenario: loads_scenario} |> decode_question_prompt(rest)
  end

  defp decode_question_prompt(%Question.Prompt{} = q, [{:comments, comments} | rest]) do
    comments = comments |> Enum.map(&decode_comment/1)
    %Question.Prompt{q | comments: comments} |> decode_question_prompt(rest)
  end

  defp decode_question_prompt(%Question.Prompt{} = q, []), do: q

  defp decode_answer_single({id, props}) do
    %Answer.Single{id: id} |> decode_answer_single(Util.to_keywords(props))
  end

  defp decode_answer_single(%Answer.Single{} = a, [{:leads_to, leads_to} | rest]) do
    %Answer.Single{a | leads_to: leads_to} |> decode_answer_single(rest)
  end

  defp decode_answer_single(%Answer.Single{} = a, [{:jumps_to, jumps_to} | rest]) do
    %Answer.Single{a | jumps_to: jumps_to} |> decode_answer_single(rest)
  end

  defp decode_answer_single(%Answer.Single{} = a, [{:loads_scenario, loads_scenario} | rest]) do
    %Answer.Single{a | loads_scenario: loads_scenario} |> decode_answer_single(rest)
  end

  defp decode_answer_single(%Answer.Single{} = a, [{:comments, comments} | rest]) do
    comments = comments |> Enum.map(&decode_comment/1)
    %Answer.Single{a | comments: comments} |> decode_answer_single(rest)
  end

  defp decode_answer_single(%Answer.Single{} = a, []), do: a

  defp decode_answer_multiple(decision) when is_map(decision) do
    %Answer.Multiple{} |> decode_answer_multiple(Util.to_keywords(decision))
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:case, "default"} | rest]) do
    %Answer.Multiple{d | case: :default} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:case, cases} | rest]) do
    %Answer.Multiple{d | case: cases} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:leads_to, leads_to} | rest]) do
    %Answer.Multiple{d | leads_to: leads_to} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:jumps_to, jumps_to} | rest]) do
    %Answer.Multiple{d | jumps_to: jumps_to} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:loads_scenario, loads_scenario} | rest]) do
    %Answer.Multiple{d | loads_scenario: loads_scenario} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, [{:comments, comments} | rest]) do
    comments = comments |> Enum.map(&decode_comment/1)
    %Answer.Multiple{d | comments: comments} |> decode_answer_multiple(rest)
  end

  defp decode_answer_multiple(%Answer.Multiple{} = d, []), do: d

  defp decode_comment(%{
         "type" => "text",
         "content" => content
       }) do
    %Comment.Text{
      content: content
    }
  end

  defp decode_comment(%{
         "type" => "image",
         "content" => content,
         "image" => image
       }) do
    %Comment.Image{
      content: content,
      image: image
    }
  end
end
