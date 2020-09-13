defmodule Chat.Driver do
  alias Chat.State
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer}
  alias Chat.Languages.Process.Interpreter.Context

  def next(
        %State{
          question: question,
          scenarios: [scenario | _],
          processes: [process | _]
        } = state,
        scenarios,
        answer
      ) do
    {:ok, scenario = %Scenario{}} = Map.fetch(scenarios, scenario)
    {:ok, process = %Process{}} = Scenario.process(scenario, process)
    {:ok, question = %Question{}} = Process.question(process, question)

    answer(scenarios, state, question, answer)
  end

  defp answer(
         scenarios,
         state = %State{},
         question = %Question{type: :Q, output: name_output},
         {:single, answer}
       ) do
    {:ok, %Answer{action: a, output: o}} = Question.answer(question, answer)

    a.(%Context{
      scenarios: scenarios,
      state: State.set_var(state, name_output, o)
    })
  end

  defp answer(
         scenarios,
         state = %State{},
         %Question{type: :C, action: action},
         :ok
       ) do
    action.(%Context{
      scenarios: scenarios,
      state: state
    })
  end

  defp answer(
         scenarios,
         state = %State{},
         %Question{
           type: :F,
           action: action,
           output: output
         },
         {:free, text}
       ) do
    action.(%Context{
      scenarios: scenarios,
      state: State.set_var(state, output, text)
    })
  end

  defp answer(
         scenarios,
         state = %State{},
         %Question{
           type: :N,
           action: action,
           output: output
         },
         {:select, select}
       ) do
    action.(%Context{
      scenarios: scenarios,
      state: State.set_var(state, output, select)
    })
  end

  @cough :cough

  def initial(scenarios) do
    {:ok, cough} = Map.fetch(scenarios, @cough)
    {:ok, %Process{id: pid} = p} = Scenario.entry(cough)
    {:ok, %Question{id: qid}} = Process.entry(p)

    State.new(qid, [@cough], [pid])
  end
end
