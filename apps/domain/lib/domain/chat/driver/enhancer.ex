defmodule Chat.Driver.Enhancer do
  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer, Text}
  alias Chat.State.Message
  alias Chat.Language.Interpreter.Context

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

    %State{state | message: message} |> dump_data()
  end

  defp create_message(
         %Question{
           type: :Q,
           text: text,
           answers: answers
         },
         data
       ) do
    Message.new(
      :Q,
      Text.render(text, data),
      %{answers: load_answers(answers, data)}
    )
  end

  defp create_message(
         %Question{
           type: :N,
           text: text,
           query: query
         },
         {state, scenarios, databases} = data
       ) do
    results =
      query.(Context.new(scenarios, databases), state)
      |> Enum.to_list()

    Message.new(
      :N,
      Text.render(text, data),
      %{results: results}
    )
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
      query.(Context.new(scenarios, databases), state)
      |> Enum.to_list()

    Message.new(
      :P,
      Text.render(text, data),
      %{product: product}
    )
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

  defp load_answers(answers, data) do
    answers
    |> Enum.map(fn %Answer{id: id, text: text} ->
      %{
        id: id,
        text: Text.render(text, data)
      }
    end)
  end

  defp dump_data(%State{question: question} = state) do
    state |> State.set_var(:previous_question, question)
  end
end
