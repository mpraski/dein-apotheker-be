defmodule Chat.Driver.Enhancer do
  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer, Text}
  alias Chat.Database
  alias Chat.State.Message
  alias Chat.Language.Memory
  alias Chat.Language.Context

  def enhance(
        state = %State{
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

    %State{state | message: message} |> save_question()
  end

  defp create_message(
         %Question{
           type: :Q,
           text: text,
           answers: answers
         },
         data
       ) do
    text = Text.render(text, data)

    input = %{answers: answers_input(answers, data)}

    Message.new(:Q, text, input)
  end

  defp create_message(
         %Question{
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

    Message.new(type, text, input)
  end

  defp create_message(
         %Question{
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

    input = %{product: product}

    Message.new(:P, text, input)
  end

  defp create_message(
         %Question{
           type: type,
           text: text
         },
         data
       )
       when type in ~w[C F]a do
    Message.new(type, Text.render(text, data))
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

  defp save_question(%State{question: question} = state) do
    state |> Memory.store(:previous_question, question)
  end
end
