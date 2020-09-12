defmodule Api.ChatHelpers do
  alias Chat.Legacy.{Question, Answer, Comment, Product}

  def id({_, question, _}), do: question

  def input({[], _, _}) do
    %{
      type: :end
    }
  end

  def input({[current | _], question, data}) do
    nil
  end

  def input(%Question.Single{answers: answers}) do
    answers = answers |> Enum.map(&input/1)

    %{
      type: :single,
      options: answers
    }
  end

  def input(%Question.Multiple{answers: answers}) do
    answers = answers |> Enum.map(&input/1)

    %{
      type: :multiple,
      options: answers
    }
  end

  def input(%Question.Prompt{}) do
    %{
      type: :prompt
    }
  end

  def input(%Answer.Single{id: id}) do
    %{
      id: id,
      content: id
    }
  end

  def input(id) when is_binary(id) do
    %{
      id: id,
      content: id
    }
  end

  def messages({[], _, _}), do: []

  def messages({[current | _], question, data}) do
    nil
  end

  defp message({%Question.Single{id: id}, _}) do
    %{
      type: :text,
      content: id
    }
  end

  defp message({%Question.Multiple{id: id}, _}) do
    %{
      type: :text,
      content: id
    }
  end

  defp message({%Question.Prompt{id: id}, _}) do
    %{
      type: :text,
      content: id
    }
  end

  defp message({%Comment.Text{content: content}, _}) do
    %{
      type: :text,
      content: content
    }
  end

  defp message(
         {%Comment.Image{
            content: content,
            image: image
          }, _}
       ) do
    %{
      type: :image,
      content: content,
      image: image
    }
  end

  defp message({%Comment.Product{product: p}, scenario}) do
    %Product{
      name: name,
      directions: directions,
      explanation: explanation,
      image: image
    } = Chat.product(scenario, p)

    %{
      type: :product,
      name: name,
      directions: directions,
      explanation: explanation,
      image: image
    }
  end
end
