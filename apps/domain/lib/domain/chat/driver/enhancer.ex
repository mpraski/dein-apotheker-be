defmodule Chat.Driver.Enhancer do
  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer, Text}
  alias Chat.State.Message
  alias Chat.Language.Interpreter.Context

  defmodule Failure do
    defexception message: "enhancement failure"
  end

  def enhance(
        state = %State{
          question: question,
          scenarios: [scenario | _],
          processes: [%StateProcess{id: process} | _]
        },
        {scenarios, _} = d
      ) do
    {:ok, scenario = %Scenario{}} = Map.fetch(scenarios, scenario)
    {:ok, process = %Process{}} = Scenario.process(scenario, process)
    {:ok, question = %Question{}} = Process.question(process, question)

    message = question |> create_message(state, d)

    %State{state | message: message}
  end

  defp create_message(
         %Question{
           type: :Q,
           text: text,
           answers: answers
         },
         state = %State{},
         {scenarios, databases}
       ) do
    Message.new(
      :Q,
      Text.render(text, state, scenarios, databases),
      %{answers: load_answers(answers, state, {scenarios, databases})}
    )
  end

  defp create_message(
         %Question{
           type: :N,
           text: text,
           query: query
         },
         state = %State{},
         {scenarios, databases}
       ) do
    results =
      query.(Context.new(scenarios, databases), state)
      |> Enum.to_list()

    Message.new(
      :N,
      Text.render(text, state, scenarios, databases),
      %{results: results}
    )
  end

  defp create_message(
         %Question{
           type: :P,
           text: text,
           query: query
         },
         state = %State{},
         {scenarios, databases}
       ) do
    [product] =
      query.(Context.new(scenarios, databases), state)
      |> Enum.to_list()

    Message.new(
      :P,
      Text.render(text, state, scenarios, databases),
      %{product: product}
    )
  end

  defp create_message(
         %Question{
           type: type,
           text: text
         },
         state = %State{},
         {scenarios, databases}
       )
       when type in ~w[C F]a do
    Message.new(type, Text.render(text, state, scenarios, databases))
  end

  defp load_answers(
         answers,
         state = %State{},
         {scenarios, databases}
       ) do
    answers
    |> Enum.map(fn %Answer{id: id, text: text} ->
      %{
        id: id,
        text: Text.render(text, state, scenarios, databases)
      }
    end)
  end
end
