defmodule Chat.Driver do
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
    {:ok, scenario = %Scenario{}} = Map.fetch(scenarios, scenario)
    {:ok, process = %Process{}} = Scenario.process(scenario, process)
    {:ok, question = %Question{}} = Process.question(process, question)

    state
    |> State.generate_id()
    |> answer(data, question, answer)
  end

  defp answer(
         state = %State{},
         {scenarios, databases},
         question = %Question{type: :Q, output: name_output},
         answer
       )
       when is_binary(answer) do
    {:ok, %Answer{action: a, output: o}} =
      Question.answer(question, String.to_existing_atom(answer))

    a.(
      Context.new(scenarios, databases),
      Memory.store(state, name_output, o)
    )
  end

  defp answer(state = %State{}, _, %Question{type: :C}, "ok") do
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
         cart
       )
       when is_list(cart) do
    {:ok, items} = state |> Memory.load(State.cart())

    items = (items ++ cart) |> Enum.uniq()

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
