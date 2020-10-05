defmodule Api.Views.Chat do
  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer, Text}
  alias Chat.Database
  alias Chat.Language.Context

  alias Api.Views.Chat.Message
  alias Api.Views.Chat.State, as: Representation

  def present(
        state = %State{
          id: id,
          question: question,
          scenarios: [scenario | _],
          processes: [%StateProcess{id: process} | _]
        },
        {scenarios, databases}
      ) do
    {:ok, scenario = %Scenario{}} = Map.fetch(scenarios, scenario)
    {:ok, process = %Process{}} = Scenario.process(scenario, process)
    {:ok, question = %Question{}} = Process.question(process, question)

    message = question |> create_message({state, scenarios, databases})

    Representation.new(id, message)
  end

  defp create_message(
         %Question{
           id: id,
           type: :Q,
           text: text,
           answers: answers
         },
         data
       ) do
    text = Text.render(text, data)

    Message.new(id, :Q, text, answers_input(answers, data))
  end

  defp create_message(
         %Question{
           id: id,
           type: type,
           text: text,
           query: query
         },
         {state, scenarios, databases} = data
       )
       when type in ~w[PN N]a do
    input =
      Context.new(scenarios, databases)
      |> query.(state)
      |> database_input()

    text = Text.render(text, data)

    Message.new(id, type, text, input)
  end

  defp create_message(
         %Question{
           id: id,
           type: :P,
           text: text,
           query: query
         },
         {state, scenarios, databases} = data
       ) do
    [product] =
      Context.new(scenarios, databases)
      |> query.(state)
      |> Enum.to_list()

    text = Text.render(text, data)

    Message.new(id, :P, text, product)
  end

  defp create_message(
         %Question{
           id: id,
           type: type,
           text: text
         },
         data
       )
       when type in ~w[C F]a do
    Message.new(id, type, Text.render(text, data))
  end

  defp answers_input(answers, data) do
    answers
    |> Enum.map(fn %Answer{id: id, text: text} ->
      %{
        id: id,
        text: Text.render(text, data)
      }
    end)
  end

  defp database_input(%Database{id: id} = db) do
    %{
      database: id,
      rows: Enum.to_list(db)
    }
  end
end
