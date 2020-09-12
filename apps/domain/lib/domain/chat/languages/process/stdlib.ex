defmodule Chat.Languages.Process.StdLib do
  alias Chat.State
  alias Chat.State.Process
  alias Chat.Scenario
  alias Chat.Languages.Process.Interpreter.Context

  defmodule Call do
    defstruct arg: nil, optional: nil, state: nil, scenarios: nil
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
      IS_NEXT: &is_next/1
    }
  end

  defp load(%Call{
         arg: a,
         optional: v,
         state: %State{processes: p} = s
       }) do
    with captured <- State.fetch_variables(s, v) do
      %State{s | processes: p ++ [Process.new(a, captured)]}
    end
  end

  defp jump(%Call{
         arg: a,
         state: %State{processes: [_ | rest]} = s
       }) do
    %State{s | processes: [Process.new(a) | rest]}
  end

  defp goto(%Call{arg: a, state: %State{} = s}) do
    %State{s | question: a}
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
    {:ok, %Scenario{actions: as}} = Map.fetch(scenarios, n)

    state = %State{s | processes: rest}

    case Map.fetch(as, id) do
      {:ok, action} ->
        action.(%Context{
          state: state,
          scenarios: scenarios
        })

      _ ->
        state
    end
  end

  defp is_loaded(%Call{arg: p, state: %State{processes: ps}}) do
    case Enum.find(ps, nil, fn %Process{id: i} -> i == p end) do
      %Process{} -> true
      _ -> false
    end
  end

  defp is_next(%Call{
         arg: c,
         state: %State{processes: [_ | [%Process{id: i} | _]]}
       }) do
    i == c
  end

  defp is_next(%Call{state: %State{processes: _}}) do
    false
  end
end
