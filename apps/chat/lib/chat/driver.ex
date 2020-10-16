defmodule Chat.Driver do
  @moduledoc """
  Driver performs the chat state transition
  """

  alias Chat.State
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer}
  alias Chat.State.Process, as: StateProcess
  alias Chat.Language.Memory
  alias Chat.Language.Context

  def next(
        %State{
          question: question,
          scenarios: [scenario | _],
          processes: [%StateProcess{id: process} | _]
        } = state,
        {scenarios, _} = data,
        answer
      ) do
    {:ok, scenario} = Map.fetch(scenarios, scenario)
    {:ok, process} = Scenario.process(scenario, process)
    {:ok, question} = Process.question(process, question)

    state
    |> State.generate_id()
    |> answer(data, question, answer)
    |> advance(data)
  end

  defp advance(
         %State{
           question: question,
           scenarios: [scenario | _],
           processes: [%StateProcess{id: process} | _]
         } = state,
         {scenarios, databases} = data
       ) do
    {:ok, scenario} = Map.fetch(scenarios, scenario)
    {:ok, process} = Scenario.process(scenario, process)

    {:ok,
     %Question{
       type: type,
       action: action
     }} = Process.question(process, question)

    if type == :CODE do
      Context.new(scenarios, databases)
      |> action.(state)
      |> advance(data)
    else
      state
    end
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         question = %Question{type: :Q, output: name_output},
         answer
       )
       when is_binary(answer) do
    answer = String.to_existing_atom(answer)

    {:ok, %Answer{action: a, output: o}} = Question.answer(question, answer)

    a.(
      Context.new(scenarios, databases),
      Memory.store(state, name_output, o)
    )
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         %Question{type: :P, action: action},
         "skip"
       ) do
    Context.new(scenarios, databases) |> action.(state)
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         %Question{type: :P, action: action},
         product
       ) do
    {:ok, items} = state |> Memory.load(State.cart())

    items = (items ++ [product]) |> Enum.uniq()

    state = state |> Memory.store(State.cart(), items)

    Context.new(scenarios, databases) |> action.(state)
  end

  defp answer(%State{} = state, _, %Question{type: :C, action: nil}, "ok") do
    {:ok, previous} = Memory.load(state, :previous_question)

    %State{state | question: previous}
  end

  defp answer(
         %State{} = state,
         {scenarios, databases},
         %Question{type: :C, action: action},
         _
       ) do
    Context.new(scenarios, databases) |> action.(state)
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         %Question{
           type: :F,
           action: action,
           output: output
         },
         text
       )
       when is_binary(text) do
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
         selection
       )
       when is_list(selection) do
    action.(
      Context.new(scenarios, databases),
      Memory.store(state, output, selection)
    )
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         %Question{
           type: :NP,
           action: action
         },
         selection
       )
       when is_list(selection) do
    {:ok, items} = state |> Memory.load(State.cart())

    items = (items ++ selection) |> Enum.uniq()

    state = state |> Memory.store(State.cart(), items)

    Context.new(scenarios, databases) |> action.(state)
  end

  @cough :cough

  def initial({scenarios, _}) do
    {:ok, cough} = Map.fetch(scenarios, @cough)
    {:ok, %Process{id: pid} = p} = Scenario.entry(cough)
    {:ok, %Question{id: qid}} = Process.entry(p)

    State.new(
      qid,
      [@cough],
      [StateProcess.new(pid)],
      %{cart: []}
    )
    |> State.generate_id()
  end
end
