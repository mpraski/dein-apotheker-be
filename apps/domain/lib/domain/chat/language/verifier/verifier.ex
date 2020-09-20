defmodule Chat.Language.Verifier do
  alias Chat.Language.Verifier.Result

  def verify(ast, scenario) do
    verify_stmts(Result.new(scenario, ast), ast)
  end

  defp verify_stmts(%Result{} = r, stmts) do
    %Result{} = Enum.reduce(stmts, r, &verify_stmt(&2, &1))
  end

  defp verify_stmt(%Result{} = r, {:call, {:ident, _}, args}) do
    Enum.reduce(args, r, &verify_expr(&2, &1))
  end

  defp verify_stmt(%Result{} = r, {:lif, a, b, c}) do
    r = r |> verify_expr(a)
    r = Enum.reduce(b, r, &verify_stmt(&2, &1))
    Enum.reduce(c, r, &verify_stmt(&2, &1))
  end

  defp verify_stmt(%Result{} = r, {:unless, a, b, c}) do
    verify_stmt(r, {:lif, a, c, b})
  end

  defp verify_stmt(%Result{} = r, {:for, {:var, i}, {:var, v}, stmts}) do
    r
    |> Result.log("iterable variable #{v} not declared", &Result.declared?(&1, v))
    |> Result.declare(i)

    Enum.reduce(stmts, r, &verify_stmt/2) |> Result.undeclare(i)
  end

  defp verify_expr(%Result{} = r, {:call, {:ident, _}, args}) do
    Enum.reduce(args, r, &verify_expr(&2, &1))
  end

  defp verify_expr(%Result{} = r, {:ident, i}) do
    r |> Result.log("process #{i} not present", &(!Result.has_process?(&1, i)))
  end

  defp verify_expr(%Result{} = r, {:with, i, _}) do
    r |> Result.log("process #{i} not present", &(!Result.has_process?(&1, i)))
  end

  defp verify_expr(%Result{} = r, {:var, v}) do
    r |> Result.log("variable #{v} not declared", &(!Result.declared?(&1, v)))
  end

  defp verify_expr(%Result{} = r, {:string, _}), do: r

  defp verify_expr(%Result{} = r, {:lor, a, b}) do
    r |> verify_expr(a) |> verify_expr(b)
  end

  defp verify_expr(%Result{} = r, {:land, a, b}) do
    r |> verify_expr(a) |> verify_expr(b)
  end

  defp verify_expr(%Result{} = r, {:equals, v, i}) do
    r |> verify_expr(v) |> verify_expr(i)
  end

  defp verify_expr(%Result{} = r, {:not_equals, v, i}) do
    r |> verify_expr(v) |> verify_expr(i)
  end
end
