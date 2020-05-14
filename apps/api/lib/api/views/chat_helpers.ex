defmodule Api.ChatHelpers do
  alias Chat.{Translator, Util, Question, Question, Answer, Comment}

  def id({_, question, _}), do: question

  def input({[], _, _}) do
    %{
      type: :end
    }
  end

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
         comments_scenario <- data |> Map.get(:comments_scenario, current),
         messages <- comments ++ [question] do
      messages
      |> Enum.map(&message/1)
      |> Enum.map(&translate_message(&1, language, current, comments_scenario))
      |> Enum.map(&Util.pop(&1, :kind))
    end
  end

  defp message(%Question.Single{id: id}) do
    %{
      kind: :question,
      type: :text,
      content: id
    }
  end

  defp message(%Question.Multiple{id: id}) do
    %{
      kind: :question,
      type: :text,
      content: id
    }
  end

  defp message(%Question.Prompt{id: id}) do
    %{
      kind: :question,
      type: :text,
      content: id
    }
  end

  defp message(%Comment.Text{content: content}) do
    %{
      kind: :comment,
      type: :text,
      content: content
    }
  end

  defp message(%Comment.Image{
         content: content,
         image: image
       }) do
    %{
      kind: :comment,
      type: :image,
      content: content,
      image: image
    }
  end

  defp message(%Comment.Buy{
         name: name,
         image: image,
         price: price
       }) do
    %{
      kind: :comment,
      type: :buy,
      name: name,
      image: image,
      price: price
    }
  end

  defp translate_message(item, language, scenario, comments_scenario) do
    with translate_question <-
           &Translator.translate(
             &1,
             language: language,
             scenario: scenario,
             keys: [:content]
           ),
         translate_comment <-
           &Translator.translate(
             &1,
             language: language,
             scenario: comments_scenario,
             keys: [:content, :name, :price, :image]
           ) do
      case item |> Map.get(:kind) do
        :question -> translate_question.(item)
        :comment -> translate_comment.(item)
      end
    end
  end
end
