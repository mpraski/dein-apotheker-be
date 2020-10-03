defmodule Chat.Language.StdLib do
  alias Chat.State
  alias Chat.State.Process
  alias Chat.Scenario
  alias Chat.Database
  alias Chat.Language.Memory
  alias Chat.Language.Context

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

  def functions do
    %{
      LOAD: &load/1,
      LOAD_WITH: &load_with/1,
      JUMP: &jump/1,
      GO: &go/1,
      FINISH: &finish/1,
      IS_LOADED: &is_loaded/1,
      IS_NEXT: &is_next/1,
      DEFER: &defer/1,
      SAVE: &save/1,
      TO_TEXT: &to_text/1,
      ROWS: &rows/1,
      COLS: &cols/1,
      SIZE: &size/1,
      LIST: &list/1,
      ADD: &add/1,
      MATCH: &match/1
    }
  end

  defp load(%Call{args: [%State{processes: p} = s, proc]}) do
    %State{s | processes: p ++ [Process.new(proc)]}
  end

  defp load_with(%Call{args: [%State{processes: p} = s, proc | vars], context: c}) do
    captured =
      Map.merge(
        Memory.load_many(s, vars),
        Memory.load_many(c, vars)
      )

    %State{s | processes: p ++ [Process.new(proc, captured)]}
  end

  defp jump(%Call{args: [%State{processes: [_ | rest]} = s, proc]}) do
    %State{s | processes: [Process.new(proc) | rest]}
  end

  defp jump(%Call{args: [%State{processes: []} = s, proc]}) do
    %State{s | processes: [Process.new(proc)]}
  end

  defp go(%Call{args: [%State{} = s, question]}) do
    %State{s | question: question}
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

  defp finish(
         %Call{
           args: [
             %State{
               processes: [%Process{id: id}],
               scenarios: [n | _]
             } = s
           ],
           context: %Context{scenarios: scenarios}
         } = c
       ) do
    {:ok, scenario} = Map.fetch(scenarios, n)
    {:ok, action} = Scenario.action(scenario, id)

    action.(%Call{c | args: [%State{s | processes: []}]})
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

  defp save(%Call{args: [m, n], context: c}) do
    {:ok, v} = Memory.load(c, n)
    Memory.store(m, n, v)
  end

  defp to_text(%Call{args: [_ | args]}) do
    args
    |> Enum.map(&to_string/1)
    |> Enum.join(" ")
  end

  defp to_text(%Call{}), do: ""

  defp size(%Call{args: [_, v]}) when is_list(v), do: length(v)

  defp rows(%Call{args: [_, db]}), do: Database.height(db)

  defp cols(%Call{args: [_, db]}), do: Database.width(db)

  defp add(%Call{args: [_, a, b]}), do: a + b

  defp list(%Call{args: [_ | items]}), do: items

  defp match(%Call{}), do: nil
end
