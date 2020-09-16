defmodule Chat.Languages.Process.Interpreter do
  alias Chat.State
  alias Chat.Languages.Process.StdLib
  alias Chat.Languages.Process.StdLib.Call

  defmodule Context do
    defstruct scenarios: nil, state: nil
  end

  defmodule Failure do
    defexception message: "interpretation failure"
  end

  def interpret(program) do
    &interpret_stmts(program, %Context{state: %State{}} = &1)
  end

  defp interpret_stmts(stmts, %Context{state: state} = c) do
    %State{} = Enum.reduce(stmts, state, &interpret_stmt(&1, %Context{c | state: &2}))
  end

  defp interpret_stmt({:call, {:ident, f}, args}, context) do
    %State{} = call_func(f, args, context)
  end

  defp interpret_stmt({:lif, a, b, c}, context) do
    %State{} =
      with ap <- interpret_expr(a, context) do
        if ap do
          interpret_stmts(b, context)
        else
          interpret_stmts(c, context)
        end
      end
  end

  defp interpret_stmt({:unless, a, b, c}, context) do
    %State{} = interpret_stmt({:lif, a, c, b}, context)
  end

  defp interpret_stmt({:for, {:var, i}, {:var, v}, stmts}, %Context{state: state} = c) do
    case State.get_var(state, v) do
      {:ok, items} ->
        state
        |> Enum.reduce(items, fn a, s ->
          with s <- State.set_var(s, i, a) do
            interpret_stmts(stmts, %Context{c | state: s})
          end
        end)
        |> State.delete_var(i)

      _ ->
        state
    end
  end

  defp interpret_expr({:call, {:ident, f}, args}, context) do
    call_func(f, args, context)
  end

  defp interpret_expr({:ident, i}, _) when is_atom(i), do: i

  defp interpret_expr({:with, i, w}, context) do
    {interpret_expr(i, context), Enum.map(w, &interpret_expr(&1, context))}
  end

  defp interpret_expr({:var, v}, %Context{state: state}) when is_atom(v) do
    State.all_vars(state) |> Map.has_key?(v)
  end

  defp interpret_expr({:string, s}, _) when is_list(s), do: to_string(s)

  defp interpret_expr({:lor, a, b}, context) do
    interpret_expr(a, context) || interpret_expr(b, context)
  end

  defp interpret_expr({:land, a, b}, context) do
    interpret_expr(a, context) && interpret_expr(b, context)
  end

  defp interpret_expr({:equals, v, i}, %Context{state: state} = c) do
    with v <- interpret_expr(v, c),
         i <- interpret_expr(i, c) do
      State.get_var(state, v) == {:ok, i}
    end
  end

  defp interpret_expr({:not_equals, v, i}, context) do
    interpret_expr({:equals, v, i}, context) |> Kernel.not()
  end

  defp call_func(n, args, %Context{state: state, scenarios: scenarios} = context) do
    args = Enum.map(args, &interpret_expr(&1, context))

    call = %Call{
      args: args,
      state: state,
      scenarios: scenarios
    }

    case Map.fetch(StdLib.functions(), n) do
      {:ok, f} -> f.(call)
      _ -> raise Failure, message: "function #{n} not in std lib"
    end
  end
end
