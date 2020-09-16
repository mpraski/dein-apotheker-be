defmodule Chat.Languages.Process.StdLib do
  alias Chat.State
  alias Chat.State.Process
  alias Chat.Scenario
  alias Chat.Languages.Process.Interpreter.Context

  defmodule Call do
    defstruct args: [], state: nil, scenarios: nil
  end

  defmodule Failure do
    defexception message: "std lib failure"
  end

  def functions do
    %{
      LOAD: &load/1,
      JUMP: &jump/1,
      GOTO: &goto/1,
      FINISH: &finish/1,
      IS_LOADED: &is_loaded/1,
      IS_NEXT: &is_next/1,
      DEFER: &defer/1
    }
  end

  defp load(%Call{
         args: [proc],
         state: %State{processes: p} = s
       }) do
    %State{s | processes: p ++ [Process.new(proc)]}
  end

  defp load(%Call{
         args: [{proc, vars}],
         state: %State{processes: p} = s
       }) do
    with captured <- State.fetch_variables(s, vars) do
      %State{s | processes: p ++ [Process.new(proc, captured)]}
    end
  end

  defp jump(%Call{
         args: [proc],
         state: %State{processes: [_ | rest]} = s
       }) do
    %State{s | processes: [Process.new(proc) | rest]}
  end

  defp jump(%Call{
         args: [proc],
         state: %State{processes: []} = s
       }) do
    %State{s | processes: [Process.new(proc)]}
  end

  defp goto(%Call{args: [question], state: %State{} = s}) do
    %State{s | question: question}
  end

  defp finish(%Call{state: %State{processes: []}}) do
    raise Failure, message: "empty process queue"
  end

  defp finish(%Call{
         state:
           %State{
             processes: [%Process{id: id} | rest],
             scenarios: [n | _]
           } = s,
         scenarios: scenarios
       }) do
    {:ok, scenario} = Map.fetch(scenarios, n)
    {:ok, action} = Scenario.action(scenario, id)

    action.(%Context{
      state: %State{s | processes: rest},
      scenarios: scenarios
    })
  end

  defp is_loaded(%Call{args: [proc], state: %State{processes: ps}}) do
    case Enum.find(ps, fn %Process{id: i} -> i == proc end) do
      %Process{} -> true
      _ -> false
    end
  end

  defp is_next(%Call{
         args: [proc],
         state: %State{processes: [_ | [%Process{id: i} | _]]}
       }) do
    i == proc
  end

  defp is_next(%Call{state: %State{processes: _}}) do
    false
  end

  defp defer(%Call{args: [], state: %State{} = s}), do: s
end
