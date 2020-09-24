defmodule Chat.Driver do
  alias Chat.State
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer}
  alias Chat.State.Process, as: StateProcess
  alias Chat.Language.Interpreter.Context
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
      State.set_var(state, name_output, o)
    )
  end

  defp answer(state = %State{}, _, %Question{type: :C}, {:comment, "ok"}) do
    {:ok, previous} = State.get_var(state, :previous_question)

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
      State.set_var(state, output, text)
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
         {:select, select}
       ) do
    action.(
      Context.new(scenarios, databases),
      State.set_var(state, output, String.to_existing_atom(select))
    )
  end

  @cough :cough

  def initial(scenarios) do
    {:ok, cough} = Map.fetch(scenarios, @cough)
    {:ok, %Process{id: pid} = p} = Scenario.entry(cough)
    {:ok, %Question{id: qid}} = Process.entry(p)

    State.new(qid, [@cough], [StateProcess.new(pid)])
  end
end
