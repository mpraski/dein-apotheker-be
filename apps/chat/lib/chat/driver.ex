defmodule Chat.Driver do
  @moduledoc """
  Driver performs the chat state transition
  """

  alias Chat.State
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer}
  alias Chat.State.Process, as: StateProcess
  alias Chat.Language.Memory
  alias Chat.Language.Interpreter
  alias Chat.Language.Parser

  import Parser

  @prev_question :previous_question

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
    |> stamp()
    |> answer(question, answer)
    |> advance()
  end

  defp stamp(state), do: State.generate_id(state)

  defp answer(state, %Question{type: :Q, output: output} = question, answer) do
    answer = String.to_existing_atom(answer)

    {:ok, %Answer{action: a, output: o}} = Question.answer(question, answer)

    Memory.store(state, output, o) |> Interpreter.interpret(a).()
  end

  defp answer(state, %Question{type: :P, query: query} = question, answer) do
    answer = String.to_existing_atom(answer)

    {:ok, %Answer{action: action}} = Question.answer(question, answer)

    [product] =
      state
      |> Interpreter.interpret(query).()
      |> Enum.to_list()

    tape = %{
      product_id: Keyword.get(product, :ID)
    }

    Interpreter.interpret(action, tape).(state)
  end

  defp answer(state, %Question{type: :C, action: nil}, _) do
    {:ok, previous} = Memory.load(state, @prev_question)

    %State{state | question: previous}
  end

  defp answer(state, %Question{type: :C, action: action}, _) do
    Interpreter.interpret(action).(state)
  end

  defp answer(
         state,
         %Question{
           type: :F,
           action: action,
           output: output
         },
         text
       ) do
    state
    |> Memory.store(output, text)
    |> Interpreter.interpret(action).()
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
    state
    |> Memory.store(output, selection)
    |> Interpreter.interpret(action).()
  end

  defp answer(
         state,
         %Question{
           type: :PN,
           action: action
         },
         products
       ) do
    args = %{
      products: products
    }

    prog = ~p/CART_MANY([products]);/

    state
    |> Interpreter.interpret(prog, args).()
    |> Interpreter.interpret(action).()
  end

  defp advance(
         %State{
           question: question,
           scenarios: [scenario | _],
           processes: [%StateProcess{id: process} | _]
         } = state
       ) do
    %Question{
      type: type,
      action: action
    } = Chat.question(scenario, process, question)

    case type do
      :C ->
        state

      :CODE ->
        state |> Interpreter.interpret(action).() |> advance()

      _ ->
        state |> Memory.store(@prev_question, question)
    end
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
