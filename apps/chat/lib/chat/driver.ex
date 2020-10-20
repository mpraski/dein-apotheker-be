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
  alias Chat.Language.Interpreter

  def next(
        %State{
          question: question,
          scenarios: [scenario | _],
          processes: [%StateProcess{id: process} | _]
        } = state,
        answer
      ) do
    question = Chat.question(scenario, process, question)

    state
    |> State.generate_id()
    |> answer(question, answer)
    |> advance()
  end

  defp advance(
         %State{
           question: question,
           scenarios: [scenario | _],
           processes: [%StateProcess{id: process} | _]
         } = state
       ) do
    IO.inspect(state)

    %Question{
      type: type,
      action: action
    } = Chat.question(scenario, process, question)

    case type do
      :C ->
        state

      :CODE ->
        Context.new()
        |> Interpreter.interpret(action).(state)
        |> advance()

      _ ->
        state |> Memory.store(:previous_question, question)
    end
  end

  defp answer(state, question = %Question{type: :Q, output: name_output}, answer)
       when is_binary(answer) do
    answer = String.to_existing_atom(answer)

    {:ok, %Answer{action: a, output: o}} = Question.answer(question, answer)

    Interpreter.interpret(a).(
      Context.new(),
      Memory.store(state, name_output, o)
    )
  end

  defp answer(state, %Question{type: :P, action: action}, "skip") do
    Context.new() |> Interpreter.interpret(action).(state)
  end

  defp answer(state, %Question{type: :P, action: action}, product) do
    {:ok, items} = state |> Memory.load(State.cart())

    items = (items ++ [product]) |> Enum.uniq()

    state = state |> Memory.store(State.cart(), items)

    Context.new() |> Interpreter.interpret(action).(state)
  end

  defp answer(state, %Question{type: :C, action: nil}, _) do
    {:ok, previous} = Memory.load(state, :previous_question)

    %State{state | question: previous}
  end

  defp answer(state, %Question{type: :C, action: action}, _) do
    Context.new() |> Interpreter.interpret(action).(state)
  end

  defp answer(
         state,
         %Question{
           type: :F,
           action: action,
           output: output
         },
         text
       )
       when is_binary(text) do
    Interpreter.interpret(action).(
      Context.new(),
      Memory.store(state, output, text)
    )
  end

  defp answer(
         state,
         %Question{
           type: :N,
           action: action,
           output: output
         },
         selection
       ) do
    Interpreter.interpret(action).(
      Context.new(),
      Memory.store(state, output, selection)
    )
  end

  defp answer(
         state,
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

    Context.new() |> Interpreter.interpret(action).(state)
  end

  @cough :cough

  def initial() do
    {:ok, %Process{id: pid} = p} = Chat.scenario(@cough) |> Scenario.entry()
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
