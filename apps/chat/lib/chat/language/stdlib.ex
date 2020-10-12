defmodule Chat.Language.StdLib do
  @moduledoc """
  StdLib of the language
  """

  alias Chat.State
  alias Chat.State.Process
  alias Chat.Scenario
  alias Chat.Scenario.Process, as: ScenarioProcess
  alias Chat.Scenario.Question
  alias Chat.Database
  alias Chat.Language.Memory
  alias Chat.Language.Context

  defmodule Call do
    @moduledoc """
    Call represents a function call runtime context
    """

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
      INJECT_WITH: &inject_with/1,
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
    captured = capture(s, c, vars)

    %State{s | processes: p ++ [Process.new(proc, captured)]}
  end

  defp inject_with(%Call{args: [%State{processes: [p | r]} = s, proc | vars], context: c}) do
    captured = capture(s, c, vars)

    %State{s | processes: [p | [Process.new(proc, captured) | r]]}
  end

  defp jump(%Call{
         args: [%State{processes: [_ | rest], scenarios: [n | _]} = s, proc],
         context: %Context{scenarios: scenarios}
       }) do
    {:ok, scenario} = Map.fetch(scenarios, n)
    {:ok, process} = scenario |> Scenario.process(proc)
    {:ok, %Question{id: qid}} = ScenarioProcess.entry(process)

    %State{s | question: qid, processes: [Process.new(proc) | rest]}
  end

  defp jump(%Call{
         args: [%State{processes: [], scenarios: [n | _]} = s, proc],
         context: %Context{scenarios: scenarios}
       }) do
    {:ok, scenario} = Map.fetch(scenarios, n)
    {:ok, process} = scenario |> Scenario.process(proc)
    {:ok, %Question{id: qid}} = ScenarioProcess.entry(process)

    %State{s | question: qid, processes: [Process.new(proc)]}
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

    %State{
      processes: [%Process{id: id} | _]
    } = state = action.(%Call{c | args: [%State{s | processes: rest}]})

    {:ok, process} = scenario |> Scenario.process(id)
    {:ok, %Question{id: qid}} = ScenarioProcess.entry(process)

    %State{state | question: qid}
  end

  defp finish(
         %Call{
           args: [
             %State{
               processes: [%Process{id: id}],
               scenarios: [c, n | r]
             } = s
           ],
           context: %Context{scenarios: scenarios}
         } = c
       ) do
    {:ok, scenario} = Map.fetch(scenarios, c)
    {:ok, action} = Scenario.action(scenario, id)

    state = action.(%Call{c | args: [%State{s | processes: []}]})

    {:ok, scenario} = Map.fetch(scenarios, n)
    {:ok, process} = Scenario.entry(scenario)
    {:ok, %Question{id: qid}} = ScenarioProcess.entry(process)

    %State{state | question: qid, processes: [Process.new(process.id)], scenarios: [n | r]}
  end

  defp finish(%Call{
         args: [
           %State{
             scenarios: [_]
           } = state
         ]
       }) do
    state |> Memory.store(:terminal, true)
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
    |> deep_flat_map()
    |> Enum.map(&to_string/1)
    |> Enum.join(" ")
  end

  defp to_text(%Call{}), do: ""

  defp size(%Call{args: [_, v]}) when is_list(v), do: length(v)

  defp rows(%Call{args: [_, db]}), do: Database.height(db)

  defp cols(%Call{args: [_, db]}), do: Database.width(db)

  defp add(%Call{args: [_, a, b]}), do: a + b

  defp list(%Call{args: [_ | items]}), do: items

  defp match(%Call{
         args: [
           %State{} = s,
           api,
           water,
           swallow,
           transport,
           single
         ],
         context: %Context{databases: databases}
       }) do
    {:ok, products} = databases |> Map.fetch(:Products)
  end

  defp deep_flat_map(m) do
    Enum.flat_map(m, fn
      l when is_list(l) -> deep_flat_map(l)
      o -> [o]
    end)
  end

  defp capture(m1, m2, vars) do
    Map.merge(
      Memory.load_many(m1, vars),
      Memory.load_many(m2, vars)
    )
  end
end
