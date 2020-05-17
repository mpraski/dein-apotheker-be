defmodule Chat.Decoder do
  alias Chat.{Question, Answer, Product, Comment, Util}

  def decode_start(%{"start" => start}), do: start

  def decode_questions(%{"questions" => questions}) do
    questions |> Enum.map(&decode_question/1)
  end

  def decode_products(%{"products" => nil}), do: []

  def decode_products(%{"products" => products}) do
    (products || []) |> Enum.map(&decode_product/1)
  end

  def decode_products(_), do: []

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
          } = q}
       )
       when is_list(answers) and is_list(decisions) do
    decisions = decisions |> Enum.map(&decode_answer_multiple/1)
    load_scenarios = q |> Map.get("load_scenarios", false)

    %Question.Multiple{
      id: id,
      answers: answers,
      decisions: decisions,
      load_scenarios: load_scenarios
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

  defp decode_question({
         id,
         %{
           "type" => "message",
           "leads_to" => leads_to,
           "comments" => comments
         }
       }) do
    comments = comments |> Enum.map(&decode_comment/1)

    %Question.Message{
      id: id,
      leads_to: leads_to,
      comments: comments
    }
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

  defp decode_comment(%{
         "type" => "buy",
         "name" => name,
         "image" => image,
         "price" => price
       }) do
    %Comment.Buy{
      name: name,
      image: image,
      price: price
    }
  end

  defp decode_comment(%{
         "type" => "product",
         "product" => product
       }) do
    %Comment.Product{
      product: product
    }
  end

  defp decode_product(
         {id,
          %{
            "name" => name,
            "directions" => directions,
            "explanation" => explanation,
            "image" => image
          }}
       ) do
    %Product{
      id: id,
      name: name,
      directions: directions,
      explanation: explanation,
      image: image
    }
  end
end
