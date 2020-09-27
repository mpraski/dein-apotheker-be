defmodule Chat.Driver do
  alias Chat.State
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer}
  alias Chat.State.Process, as: StateProcess
  alias Chat.Language.Memory
  alias Chat.Language.Context
  alias Chat.Driver.Enhancer

  def next(
        %State{
          question: question,
          scenarios: [scenario | _],
          processes: [%StateProcess{id: process} | _]
        } = state,
        {scenarios, _} = data,
        answer
      ) do
    {:ok, scenario = %Scenario{}} = Map.fetch(scenarios, scenario)
    {:ok, process = %Process{}} = Scenario.process(scenario, process)
    {:ok, question = %Question{}} = Process.question(process, question)

    state
    |> answer(data, question, answer)
    |> Enhancer.enhance(data)
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         question = %Question{type: :Q, output: name_output},
         {:single, answer}
       ) do
    {:ok, %Answer{action: a, output: o}} =
      Question.answer(question, String.to_existing_atom(answer))

    a.(
      Context.new(scenarios, databases),
      Memory.store(state, name_output, o)
    )
  end

  defp answer(state = %State{}, _, %Question{type: :C}, {:comment, "ok"}) do
    {:ok, previous} = Memory.load(state, :previous_question)

    %State{state | question: previous}
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         %Question{
           type: :F,
           action: action,
           output: output
         },
         {:free, text}
       ) do
    action.(
      Context.new(scenarios, databases),
      Memory.store(state, output, text)
    )
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         %Question{
           type: :N,
           action: action,
           output: output
         },
         {:selection, selection}
       ) do
    action.(
      Context.new(scenarios, databases),
      Memory.store(state, output, selection)
    )
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         %Question{
           type: :B,
           action: action
         },
         {:cart, cart}
       ) do
    {:ok, items} = state |> Memory.load(State.cart())

    items = (items ++ cart) |> Enum.uniq()

    state = state |> Memory.store(State.cart(), items)

    Context.new(scenarios, databases) |> action.(state)
  end

  @cough :cough

  def initial({scenarios, _} = data) do
    {:ok, cough} = Map.fetch(scenarios, @cough)
    {:ok, %Process{id: pid} = p} = Scenario.entry(cough)
    {:ok, %Question{id: qid}} = Process.entry(p)

    State.new(qid, [@cough], [StateProcess.new(pid)]) |> Enhancer.enhance(data)
  end
end
