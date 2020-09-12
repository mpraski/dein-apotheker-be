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
    &interpret_stmts(program, %Context{} = &1)
  end

  defp interpret_stmts(stmts, %Context{state: state} = c) do
    %State{} = Enum.reduce(state, stmts, &interpret_stmt(&1, %Context{c | state: &2}))
  end

  defp interpret_stmt({:call, f, a = {_, _}}, context) do
    %State{} = call_func(f, a, context)
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

  defp interpret_stmt({:for, i, v, stmts}, %Context{state: state} = c) do
    case Map.fetch(State.all_vars(state), v) do
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

  defp interpret_expr({:call, f, a = {_, _}}, context) do
    case call_func(f, a, context) do
      b when is_boolean(b) -> b
      _ -> raise Failure, message: "function doesn't return a boolean"
    end
  end

  defp interpret_expr(v, %Context{state: state}) when is_atom(v) do
    State.all_vars(state) |> Map.has_key?(v)
  end

  defp interpret_expr({:lor, a, b}, context) do
    interpret_expr(a, context) || interpret_expr(b, context)
  end

  defp interpret_expr({:land, a, b}, context) do
    interpret_expr(a, context) && interpret_expr(b, context)
  end

  defp interpret_expr({:equals, v, c}, %Context{state: state}) do
    State.all_vars(state) |> check_equality(v, c)
  end

  defp interpret_expr({:not_equals, v, c}, %Context{state: state}) do
    State.all_vars(state) |> check_equality(v, c) |> Kernel.not()
  end

  defp check_equality(m, v, c) do
    case Map.fetch(m, v) do
      {:ok, a} -> a == c
      _ -> false
    end
  end

  defp call_func(n, {arg, vars}, %Context{state: state, scenarios: scenarios}) do
    call = %Call{
      arg: arg,
      optional: vars,
      state: state,
      scenarios: scenarios
    }

    case Map.fetch(StdLib.functions(), n) do
      {:ok, f} -> f.(call)
      _ -> raise Failure, message: "function #{n} not in std lib"
    end
  end
end
