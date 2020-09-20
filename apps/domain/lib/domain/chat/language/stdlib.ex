defmodule Chat.Language.StdLib do
  alias Chat.State
  alias Chat.State.Process
  alias Chat.Database
  alias Chat.Scenario
  alias Chat.Language.Interpreter.Context

  defmodule Call do
    use TypedStruct

    typedstruct do
      field(:args, list(any()), enforce: true)
      field(:context, Context.t(), enforce: true)
    end

    def new(args, context) do
      %__MODULE__{
        args: args,
        context: context
      }
    end
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
      DEFER: &defer/1,
      ROW: &row/1,
      HELLO: &hello/1
    }
  end

  defp load(%Call{args: [%State{processes: p} = s, proc]}) do
    %State{s | processes: p ++ [Process.new(proc)]}
  end

  defp load(%Call{args: [%State{processes: p} = s, {proc, vars}]}) do
    captured = State.fetch_variables(s, vars)
    %State{s | processes: p ++ [Process.new(proc, captured)]}
  end

  defp jump(%Call{args: [%State{processes: [_ | rest]} = s, proc]}) do
    %State{s | processes: [Process.new(proc) | rest]}
  end

  defp jump(%Call{args: [%State{processes: []} = s, proc]}) do
    %State{s | processes: [Process.new(proc)]}
  end

  defp goto(%Call{args: [%State{} = s, question]}) do
    %State{s | question: question}
  end

  defp finish(%Call{args: [%State{processes: []}]}) do
    raise Failure, message: "empty process queue"
  end

  defp finish(
         %Call{
           args: [
             %State{
               processes: [%Process{id: id} | rest],
               scenarios: [n | _]
             } = s
           ],
           context: %Context{scenarios: scenarios}
         } = c
       ) do
    {:ok, scenario} = Map.fetch(scenarios, n)
    {:ok, action} = Scenario.action(scenario, id)

    action.(%Call{c | args: [%State{s | processes: rest}]})
  end

  defp is_loaded(%Call{args: [%State{processes: ps}, proc]}) do
    case Enum.find(ps, fn %Process{id: i} -> i == proc end) do
      %Process{} -> true
      _ -> false
    end
  end

  defp is_next(%Call{args: [%State{processes: [_ | [%Process{id: i} | _]]}, proc]}) do
    i == proc
  end

  defp is_next(%Call{args: [%State{processes: _}]}) do
    false
  end

  defp defer(%Call{args: [%State{} = s]}), do: s

  defp row(%Call{args: [%Database{rows: [[value]]}]}), do: value

  defp row(%Call{}) do
    raise Failure, message: "expected a database with single row and column"
  end

  defp hello(%Call{args: [str]}), do: str <> " there"
end
