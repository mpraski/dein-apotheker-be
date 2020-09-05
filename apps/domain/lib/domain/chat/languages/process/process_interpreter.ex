defmodule Chat.Languages.Process.Failure do
  defexception message: "interpretation failure"
end

defmodule Chat.Languages.Process.Interpreter do
  alias Chat.State
  alias Chat.Languages.Process.{StdLib, Failure}

  def interpret(program) do
    &interpret_stmts(program, &1)
  end

  defp interpret_stmts(stmts, state) do
    state |> Enum.reduce(stmts, &interpret_stmt/2)
  end

  defp interpret_stmt({:call, f, a = {_, _}}, state) do
    %State{} = call_func(f, a, state)
  end

  defp interpret_stmt({:lif, a, b, c}, state) do
    with ap <- interpret_expr(a, state) do
      if ap do
        interpret_stmts(b, state)
      else
        interpret_stmts(c, state)
      end
    end
  end

  defp interpret_stmt({:unless, a, b, c}, state) do
    interpret_stmt({:lif, a, c, b}, state)
  end

  defp interpret_stmt({:for, i, v, stmts}, state) do
    case Map.fetch(state.variables, v) do
      {:ok, items} ->
        state
        |> Enum.reduce(items, fn a, s ->
          with s <- State.set_var(s, i, a) do
            interpret_stmts(stmts, s)
          end
        end)
        |> State.delete_var(i)

      nil ->
        state
    end
  end

  defp interpret_expr({:call, f, a = {_, _}}, state) do
    case call_func(f, a, state) do
      b when is_boolean(b) -> b
      _ -> raise Failure, message: "function doesn't return a boolean"
    end
  end

  defp interpret_expr(v, state) when is_atom(v) do
    Map.has_key?(state.variables, v)
  end

  defp interpret_expr({:lor, a, b}, state) do
    interpret_expr(a, state) || interpret_expr(b, state)
  end

  defp interpret_expr({:land, a, b}, state) do
    interpret_expr(a, state) && interpret_expr(b, state)
  end

  defp interpret_expr({:equals, v, c}, state) do
    check_equality(state.variables, v, c)
  end

  defp interpret_expr({:not_equals, v, c}, state) do
    !check_equality(state.variables, v, c)
  end

  defp check_equality(m, v, c) do
    case Map.fetch(m, v) do
      {:ok, a} -> a == c
      nil -> false
    end
  end

  defp call_func(n, {arg, vars}, state) do
    case Map.fetch(StdLib.functions(), n) do
      {:ok, f} -> f.(state, arg, vars)
      nil -> raise Failure, message: "function #{n} not in std lib"
    end
  end
end
