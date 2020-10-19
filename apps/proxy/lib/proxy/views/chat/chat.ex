defmodule Proxy.Views.Chat do
  @moduledoc """
  Chat presents the chat data structures to the frontend
  """

  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Scenario.{Question, Answer, Text}
  alias Chat.Database
  alias Chat.Language.Context
  alias Chat.Language.Interpreter

  alias Proxy.Views.Chat.{Product, Brand, API, Message}
  alias Proxy.Views.Chat.State, as: Representation

  def present(
        %State{
          id: id,
          question: question,
          scenarios: [scenario | _],
          processes: [%StateProcess{id: process} | _]
        } = state
      ) do
    question = Chat.question(scenario, process, question)

    message = question |> create_message(state)

    Representation.new(id, message)
  end

  defp create_message(
         %Question{
           id: id,
           type: :Q,
           text: text,
           answers: answers
         },
         _
       ) do
    text = Text.render(text)

    Message.new(id, :Q, text, answers_input(answers))
  end

  defp create_message(
         %Question{
           id: id,
           type: type,
           text: text,
           query: query
         },
         state
       )
       when type in ~w[PN N]a do
    input =
      Context.new()
      |> Interpreter.interpret(query).(state)
      |> database_input()

    text = Text.render(text)

    Message.new(id, type, text, input)
  end

  defp create_message(
         %Question{
           id: id,
           type: :P,
           text: text,
           query: query
         },
         state
       ) do
    [product] =
      Context.new()
      |> Interpreter.interpret(query).(state)
      |> Enum.to_list()

    text = Text.render(text)

    Message.new(id, :P, text, map_row(:Products, product))
  end

  defp create_message(
         %Question{
           id: id,
           type: :C,
           text: text
         },
         _
       ) do
    Message.new(id, :C, Text.render(text), comment_input())
  end

  defp create_message(
         %Question{
           id: id,
           type: :F,
           text: text
         },
         _
       ) do
    Message.new(id, :F, Text.render(text))
  end

  defp answers_input(answers) do
    answers
    |> Enum.map(fn %Answer{id: id, text: text} ->
      %{
        id: id,
        text: Text.render(text)
      }
    end)
  end

  defp comment_input do
    [
      %{
        id: "ok",
        text: "OK"
      }
    ]
  end

  defp database_input(%Database{id: id} = db) do
    %{
      database: id,
      rows: db |> Enum.map(&map_row(id, &1))
    }
  end

  defp map_row(:Products, row) do
    {id, name, image} = common_fields(row)

    Product.new(id, name, image)
  end

  defp map_row(:Brands, row) do
    {id, name, image} = common_fields(row)

    Brand.new(id, name, image)
  end

  defp map_row(:API, row) do
    {id, name, image} = common_fields(row)

    API.new(id, name, image)
  end

  defp common_fields(row) do
    {:ok, id} = row |> Keyword.fetch(:ID)
    {:ok, name} = row |> Keyword.fetch(:Name)
    {:ok, image} = row |> Keyword.fetch(:Image)

    {id, name, image}
  end
end
