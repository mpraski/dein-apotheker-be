defmodule Chat.Languages.Process.StdLib do
  alias Chat.{State, Process}
  alias Chat.Languages.Process.Failure

  def functions do
    %{
      LOAD: &load/3,
      JUMP: &jump/3,
      GOTO: &goto/3,
      FINISH: &finish/3,
      IS_LOADED: &is_loaded/3,
      IS_NEXT: &is_next/3
    }
  end

  defp load(%State{processes: p} = s, a, v) do
    with captured <- State.fetch_variables(s, v) do
      %State{processes: p ++ Process.new(a, captured)}
    end
  end

  defp jump(%State{processes: [_ | rest]} = s, a, v) do
    with new <- Process.new(a) do
      %State{processes: [new | rest]}
    end
  end

  defp goto(%State{} = s, a, _) do
    %State{s | question: a}
  end

  defp finish(%State{processes: []} = s, _, _) do
    raise Failure, message: "empty process queue"
  end

  # Precedence: check if theres is a rule in scenario sheet, if so do it
  # If not, just pop in the next process in the queue
  defp finish(%State{processes: [p | rest]} = s, _, _) do
    %State{processes: rest}
  end

  defp is_loaded(%State{processes: ps}, p, _) do
    case Enum.find(ps, nil, fn %Process{name: n} -> n == p end) do
      %Process{} -> true
      _ -> false
    end
  end

  defp is_next(%State{processes: [_ | [%Process{name: n} | _]]}, c, _) do
    n == c
  end

  defp is_next(%State{processes: [_]}, _, _) do
    false
  end
end
