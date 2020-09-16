defmodule Chat.Driver.Enhancer do
  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer, Text}
  alias Chat.State.Message
  alias Chat.Languages.Data.Interpreter.Context

  defmodule Failure do
    defexception message: "enhancement failure"
  end

  def enhance(
        state = %State{
          question: question,
          scenarios: [scenario | _],
          processes: [%StateProcess{id: process} | _]
        },
        scenarios,
        databases
      ) do
    {:ok, scenario = %Scenario{}} = Map.fetch(scenarios, scenario)
    {:ok, process = %Process{}} = Scenario.process(scenario, process)
    {:ok, question = %Question{}} = Process.question(process, question)

    question
    |> load_messages(state, databases)
    |> Enum.reduce(state, &State.add_message(&2, &1))
  end

  defp load_messages(
         %Question{
           type: :Q,
           text: text,
           answers: answers
         },
         state = %State{},
         databases
       ) do
    [
      Message.new(
        :Q,
        Text.render(text, state, databases),
        %{answers: load_answers(answers, state, databases)}
      )
    ]
  end

  defp load_messages(
         %Question{
           type: :N,
           text: text,
           query: query
         },
         state = %State{},
         databases
       ) do
    results =
      %Context{
        state: state,
        databases: databases
      }
      |> query.()
      |> Enum.to_list()

    [
      Message.new(
        :N,
        Text.render(text, state, databases),
        %{results: results}
      )
    ]
  end

  defp load_messages(
         %Question{
           type: :P,
           text: text,
           query: query
         },
         state = %State{},
         databases
       ) do
    [product] =
      %Context{
        state: state,
        databases: databases
      }
      |> query.()
      |> Enum.to_list()

    [
      Message.new(
        :P,
        Text.render(text, state, databases),
        %{product: product}
      )
    ]
  end

  defp load_messages(
         %Question{
           type: type,
           text: text
         },
         state = %State{},
         databases
       )
       when type in ~w[C F]a do
    [
      Message.new(type, Text.render(text, state, databases))
    ]
  end

  defp load_answers(
         answers,
         state = %State{},
         databases
       ) do
    answers
    |> Enum.map(fn %Answer{id: id, text: text} ->
      %{
        id: id,
        text: Text.render(text, state, databases)
      }
    end)
  end
end
