defmodule Api.ChatHelpers do
  alias Chat.{Translator, Question, Question, Answer, Comment}

  def id({_, question, _}), do: question

  def input({[], _, _}), do: nil

  def input({[current | _], question, data}) do
    language =
      data
      |> Map.get("language", Translator.default_language())

    current
    |> Chat.question(question)
    |> input()
    |> Translator.translate(
      language: language,
      scenario: current,
      keys: [:content]
    )
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
    with language <- data |> Map.get("language", Translator.default_language()),
         question <- Chat.question(current, question),
         comments <- data |> Map.get(:comments, []),
         comments_scenario <- data |> Map.get(:comments_scenario),
         messages <- comments ++ [question],
         translate_question <-
           &Translator.translate(
             &1,
             language: language,
             scenario: current,
             keys: [:content]
           ),
         translate_comment <-
           &Translator.translate(
             &1,
             language: language,
             scenario: comments_scenario,
             keys: [:content, :image]
           ) do
      messages |> Enum.map(&message(&1, {translate_question, translate_comment}))
    end
  end

  def message(%Question.Single{id: id}, {a, _}) do
    %{
      type: :text,
      content: id
    }
    |> a.()
  end

  def message(%Question.Multiple{id: id}, {a, _}) do
    %{
      type: :text,
      content: id
    }
    |> a.()
  end

  def message(%Question.Prompt{id: id}, {a, _}) do
    %{
      type: :text,
      content: id
    }
    |> a.()
  end

  def message(%Comment.Text{content: content}, {_, b}) do
    %{
      type: :text,
      content: content
    }
    |> b.()
  end

  def message(
        %Comment.Image{
          content: content,
          image: image
        },
        {_, b}
      ) do
    %{
      type: :image,
      content: content,
      image: image
    }
    |> b.()
  end
end
