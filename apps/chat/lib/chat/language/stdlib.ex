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
  alias Chat.Language.Parser
  alias Chat.Language.Interpreter

  import Parser

  defmodule Call do
    @moduledoc """
    Call represents a function call runtime context
    """

    use TypedStruct

    typedstruct do
      field(:args, list(any()), enforce: true)
      field(:memory, Memory.t(), enforce: true)
    end

    def new(args, memory) do
      %__MODULE__{
        args: args,
        memory: memory
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
      DELETE: &delete/1,
      TO_TEXT: &to_text/1,
      MAP: &map/1,
      ROWS: &rows/1,
      COLS: &cols/1,
      SIZE: &size/1,
      COUNT: &count/1,
      AT: &at/1,
      REM: &rem/1,
      MATCH: &match/1,
      CART: &cart/1,
      CART_MANY: &cart_many/1
    }
  end

  defp load(%Call{args: [%State{processes: p} = state, proc]}) do
    %State{state | processes: p ++ [Process.new(proc)]}
  end

  defp load_with(%Call{
         args: [
           %State{processes: p} = state,
           proc | vars
         ],
         memory: mem
       }) do
    captured = capture(state, mem, vars)

    %State{state | processes: p ++ [Process.new(proc, captured)]}
  end

  defp inject_with(%Call{
         args: [
           %State{processes: [p | r]} = state,
           proc | vars
         ],
         memory: mem
       }) do
    captured = capture(state, mem, vars)

    %State{state | processes: [p | [Process.new(proc, captured) | r]]}
  end

  defp jump(%Call{
         args: [%State{processes: [_ | rest], scenarios: [n | _]} = state, proc]
       }) do
    question_id = question_id(n, proc)

    %State{state | question: question_id, processes: [Process.new(proc) | rest]}
  end

  defp jump(%Call{
         args: [%State{processes: [], scenarios: [n | _]} = state, proc]
       }) do
    question_id = question_id(n, proc)

    %State{state | question: question_id, processes: [Process.new(proc)]}
  end

  defp jump(%Call{args: [%State{processes: []} = state, proc]}) do
    %State{state | processes: [Process.new(proc)]}
  end

  defp go(%Call{args: [%State{} = state, question]}) do
    %State{state | question: question}
  end

  defp finish(%Call{
         args: [
           %State{
             processes: [%Process{id: id} | rest],
             scenarios: [n | _]
           } = state
         ],
         memory: mem
       }) do
    scenario = Chat.scenario(n)
    {:ok, action} = Scenario.action(scenario, id)

    %State{
      processes: [%Process{id: id} | _]
    } =
      state =
      Interpreter.interpret(action, mem).(%State{
        state
        | processes: rest
      })

    {:ok, process} = scenario |> Scenario.process(id)
    {:ok, %Question{id: qid}} = ScenarioProcess.entry(process)

    %State{state | question: qid}
  end

  defp finish(%Call{
         args: [
           %State{
             processes: [%Process{id: id}],
             scenarios: [c, n | r]
           } = state
         ],
         memory: mem
       }) do
    {:ok, action} = Chat.scenario(c) |> Scenario.action(id)

    action = action |> Interpreter.interpret(mem)

    state = action.(%State{state | processes: []})

    {:ok, process} = Chat.scenario(n) |> Scenario.entry()
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

  defp defer(%Call{args: [%State{} = state]}), do: state

  defp save(%Call{args: [m, n], memory: mem}) do
    {:ok, v} = Memory.load(mem, n)
    Memory.store(m, n, v)
  end

  defp delete(%Call{args: [m, n]}) do
    Memory.delete(m, n)
  end

  defp map(%Call{args: [r, func, list]} = c) do
    {:ok, f} = functions() |> Map.fetch(func)
    call = &f.(%Call{c | args: [r, &1]})
    list |> Enum.map(call)
  end

  defp to_text(%Call{args: [_ | args]}) do
    args
    |> deep_flat_map()
    |> Enum.map(&to_string/1)
    |> Enum.join(" ")
  end

  defp to_text(%Call{}), do: ""

  defp count(%Call{args: [_, i, l]}) when is_list(l), do: Enum.count(l, &(&1 == i))

  defp size(%Call{args: [_, v]}) when is_list(v), do: length(v)

  defp rows(%Call{args: [_, db]}), do: Database.height(db)

  defp cols(%Call{args: [_, db]}), do: Database.width(db)

  defp at(%Call{args: [_, index, items]}), do: items |> Enum.at(index)

  defp rem(%Call{args: [_, n, d]}), do: Kernel.rem(n, d)

  defp match(%Call{
         args: [
           _,
           api,
           water,
           swallow,
           transport,
           fly,
           single
         ]
       }) do
    args = %{
      water: water,
      swallow: swallow,
      transport: transport,
      fly: fly,
      single: single
    }

    med_form_query = ~p"""
      SELECT ID FROM MedForm WHERE
        WithoutWater       == TO_TEXT([water]) AND
        SwallowingProblems == TO_TEXT([swallow]) AND
        Portable           == TO_TEXT([transport]) AND
        GoodForFlight      == TO_TEXT([fly]) AND
        DosedIndividually  == TO_TEXT([single])
    """

    prog = med_form_query |> Interpreter.interpret(args)

    forms = prog.(nil) |> Database.single_column_rows()

    args = %{
      api: api,
      forms: forms
    }

    match_query = ~p"""
      SELECT *
      FROM Products
      WHERE APIID == [api] AND MedFormID IN [forms]
    """

    prog = match_query |> Interpreter.interpret(args)

    [forms, prog.(nil)]
  end

  defp cart(%Call{args: [state | _], memory: mem}) do
    {:ok, items} = state |> Memory.load(:cart)
    {:ok, product_id} = mem |> Memory.load(:product_id)

    items = (items ++ [product_id]) |> Enum.uniq()

    state |> Memory.store(:cart, items)
  end

  defp cart_many(%Call{args: [state, product_ids]}) do
    {:ok, items} = state |> Memory.load(:cart)

    items = (items ++ product_ids) |> Enum.uniq()

    state |> Memory.store(:cart, items)
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

  defp question_id(scenario_id, process_id) do
    process = Chat.process(scenario_id, process_id)

    {:ok, %Question{id: question_id}} = ScenarioProcess.entry(process)

    question_id
  end
end
