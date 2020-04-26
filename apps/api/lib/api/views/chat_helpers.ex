defmodule Api.ChatHelpers do
  alias Chat.{Translator, Question, Question, Answer, Comment}

  def id({_, question, _}), do: question

  def input({[], _, _}), do: nil

  def input({[current | _], question, _}) do
    current
    |> Chat.question(question)
    |> input()
    |> Translator.translate(scenario: current, keys: [:content])
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
    with question <- Chat.question(current, question),
         comments <- data |> Map.get(:comments, []),
         messages <- comments ++ [question] do
      messages
      |> Enum.map(&message/1)
      |> Translator.translate(scenario: current, keys: [:content, :image])
    end
  end

  def message(%Question.Single{id: id}) do
    %{
      type: :text,
      content: id
    }
  end

  def message(%Question.Multiple{id: id}) do
    %{
      type: :text,
      content: id
    }
  end

  def message(%Question.Prompt{id: id}) do
    %{
      type: :text,
      content: id
    }
  end

  def message(%Comment.Text{content: content}) do
    %{
      type: :text,
      content: content
    }
  end

  def message(%Comment.Image{
        content: content,
        image: image
      }) do
    %{
      type: :image,
      content: content,
      image: image
    }
  end
end
