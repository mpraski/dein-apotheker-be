defmodule Chat.Language.Interpreter do
  alias Chat.Database
  alias Chat.Language.Memory
  alias Chat.Language.Context
  alias Chat.Language.StdLib
  alias Chat.Language.StdLib.Call

  def interpret(program) do
    fn %Context{} = c, r ->
      {c, r} |> interpret_exprs(program) |> elem(1)
    end
  end

  defp interpret_exprs(data, exprs) do
    Enum.reduce(exprs, data, &interpret_expr(&2, &1))
  end

  defp interpret_expr(data, {:lif, exprs, otherwise}) do
    reduced =
      Enum.reduce_while(exprs, {:next, data}, fn {c, t}, {_, data} ->
        {_, c} = data |> interpret_expr(c)

        if c do
          {:halt, {:done, data |> interpret_expr(t)}}
        else
          {:cont, {:next, data}}
        end
      end)

    case reduced do
      {:done, data} -> data
      {:next, _} -> data |> interpret_expr(otherwise)
    end
  end

  defp interpret_expr({_, s} = data, {:for, {:var, i}, {:var, v}, exprs}) do
    case Memory.load(s, v) do
      {:ok, items} ->
        {c, s} =
          Enum.reduce(items, data, fn a, {c, s} ->
            {Memory.store(c, i, a), s} |> interpret_exprs(exprs)
          end)

        {Memory.delete(c, i), s}

      _ ->
        data
    end
  end

  defp interpret_expr(data, {:call, {:ident, f}, args}) do
    data |> call_func(f, args)
  end

  defp interpret_expr({c, r} = d, {:assign, {:var, v}, expr}) do
    {_, e} = d |> interpret_expr(expr)
    {Memory.store(c, v, e), r}
  end

  defp interpret_expr({c, _}, {:ident, i}) when is_atom(i), do: {c, i}

  defp interpret_expr({c, _} = data, {:with, i, w}) do
    {_, i} = data |> interpret_expr(i)

    vars = Enum.map(w, &elem(&1, 1))

    {c, {i, vars}}
  end

  defp interpret_expr({c, s}, {:var, v}) when is_atom(v) do
    {c, Map.merge(Memory.all(s), Memory.all(c)) |> Map.get(v)}
  end

  defp interpret_expr({c, _}, {:string, s}) when is_list(s), do: {c, to_string(s)}

  defp interpret_expr({c, _}, {:number, n}) when is_integer(n), do: {c, n}

  defp interpret_expr({c, _}, {:qualified_db, {:ident, d}, {:ident, n}}) do
    {c, {:qualified_db, d, n}}
  end

  defp interpret_expr({c, _}, {:qualified_ident, {:ident, d}, {:ident, n}}) do
    {c, {:qualified_ident, d, n}}
  end

  defp interpret_expr({c, _} = data, {:lor, a, b}) do
    {_, a} = data |> interpret_expr(a)
    {_, b} = data |> interpret_expr(b)

    {c, a || b}
  end

  defp interpret_expr({c, _} = data, {:land, a, b}) do
    {_, a} = data |> interpret_expr(a)
    {_, b} = data |> interpret_expr(b)

    {c, a && b}
  end

  defp interpret_expr({c, _} = data, {:equals, v, i}) do
    {_, v} = data |> interpret_expr(v)
    {_, i} = data |> interpret_expr(i)

    {c, v == i}
  end

  defp interpret_expr(data, {:not_equals, v, i}) do
    {c, r} = data |> interpret_expr({:equals, v, i})
    {c, Kernel.not(r)}
  end

  defp interpret_expr({c, _} = data, {:greater, v, i}) do
    {_, v} = data |> interpret_expr(v)
    {_, i} = data |> interpret_expr(i)

    {c, v > i}
  end

  defp interpret_expr({c, _} = data, {:greater_equal, v, i}) do
    {_, v} = data |> interpret_expr(v)
    {_, i} = data |> interpret_expr(i)

    {c, v >= i}
  end

  defp interpret_expr({c, _} = data, {:lower, v, i}) do
    {_, v} = data |> interpret_expr(v)
    {_, i} = data |> interpret_expr(i)

    {c, v < i}
  end

  defp interpret_expr({c, _} = data, {:lower_equal, v, i}) do
    {_, v} = data |> interpret_expr(v)
    {_, i} = data |> interpret_expr(i)

    {c, v <= i}
  end

  defp interpret_expr(data, {:select, columns, database, [], nil}) do
    data
    |> dump_register()
    |> interpret_from(database)
    |> interpret_select(columns)
  end

  defp interpret_expr(data, {:select, columns, database, [], where}) do
    data
    |> dump_register()
    |> interpret_from(database)
    |> interpret_select(columns)
    |> interpret_where(where)
  end

  defp interpret_expr(data, {:select, columns, database, joins, nil}) do
    data =
      data
      |> dump_register()
      |> interpret_from(database)

    joins
    |> Enum.reduce(data, &interpret_join(&2, &1))
    |> interpret_select(columns)
  end

  defp interpret_expr(data, {:select, columns, database, joins, where}) do
    data =
      data
      |> dump_register()
      |> interpret_from(database)

    joins
    |> Enum.reduce(data, &interpret_join(&2, &1))
    |> interpret_where(where)
    |> interpret_select(columns)
  end

  defp interpret_select({c, %Database{} = db}, :all), do: {c, db}

  defp interpret_select({c, %Database{id: id} = db} = d, cols) do
    indices =
      d
      |> evaluate_exprs(cols)
      |> Enum.map(&normalize_column/1)
      |> Enum.map(&Database.header_index(db, &1))

    reducer = &Enum.reduce(indices, [], fn i, acc -> acc ++ [Enum.at(&1, i)] end)

    {c, db |> Enum.map(reducer) |> Enum.into(Database.new(id))}
  end

  defp interpret_from({%Context{databases: dbs} = c, _} = d, name) do
    {_, name} = d |> interpret_expr(name)

    case name do
      {:qualified_db, name, aliaz} ->
        {:ok, db} = Map.fetch(dbs, name)
        {Memory.store(c, qualified_db_alias(aliaz), name), db}

      name ->
        {:ok, db} = Map.fetch(dbs, name)
        {c, db}
    end
  end

  defp interpret_join({_, r} = d, {:join, name, on_expr}) do
    {c, {:qualified_db, name, aliaz}} = d |> interpret_expr(name)

    c = Memory.store(c, qualified_db_alias(aliaz), name)

    {c, {c, aliaz, r} |> evaluate_on_expr(on_expr)}
  end

  defp interpret_where({c, %Database{id: id} = db}, where_expr) do
    db =
      db
      |> Enum.filter(&evaluate_where_expr({c, &1}, where_expr))
      |> Enum.into(Database.new(id))

    {c, db}
  end

  defp evaluate_where_expr(data, {:lor, a, b}) do
    a = data |> evaluate_where_expr(a)
    b = data |> evaluate_where_expr(b)

    a || b
  end

  defp evaluate_where_expr(data, {:land, a, b}) do
    a = data |> evaluate_where_expr(a)
    b = data |> evaluate_where_expr(b)

    a && b
  end

  defp evaluate_where_expr({_, r} = d, {:equals, v, i}) do
    {_, v} = d |> interpret_expr(v)
    {_, i} = d |> interpret_expr(i)

    v =
      Keyword.get(r, normalize_column(v)) ||
        Keyword.get(r, possibly_qualified_column(v))

    v == i
  end

  defp evaluate_where_expr(data, {:not_equals, v, i}) do
    data |> evaluate_where_expr({:equals, v, i}) |> Kernel.not()
  end

  defp evaluate_on_expr(data, {:lor, a, b}) do
    a = data |> evaluate_on_expr(a)
    b = data |> evaluate_on_expr(b)

    Database.union(a, b)
  end

  defp evaluate_on_expr(data, {:land, a, b}) do
    a = data |> evaluate_on_expr(a)
    b = data |> evaluate_on_expr(b)

    Database.intersection(a, b)
  end

  defp evaluate_on_expr(data, {:equals, v, i}) do
    {db1, db2, col1, col2, n} = data |> prepare_join(v, i)

    Database.join(db1, db2, col1, col2, n, &Kernel.==/2)
  end

  defp evaluate_on_expr(data, {:not_equals, v, i}) do
    {db1, db2, col1, col2, n} = data |> prepare_join(v, i)

    Database.join(db1, db2, col1, col2, n, &Kernel.!=/2)
  end

  defp prepare_join({%Context{databases: dbs} = c, n, db}, v, i) do
    {_, {:qualified_ident, n1, col1}} = {c, nil} |> interpret_expr(v)
    {_, {:qualified_ident, n2, col2}} = {c, nil} |> interpret_expr(i)

    col1 = normalize_column(col1)
    col2 = normalize_column(col2)

    {target, col1, col2} =
      if n1 == n do
        {n1, col2, col1}
      else
        {n2, col1, col2}
      end

    {:ok, target} = Memory.load(c, qualified_db_alias(target))
    {:ok, target} = Map.fetch(dbs, target)

    {db, target, col1, col2, n}
  end

  defp normalize_column(v) when is_atom(v), do: v

  defp normalize_column(v) when is_binary(v), do: String.to_existing_atom(v)

  defp normalize_column({:qualified_ident, db, col}) do
    qualified_col_alias(db, col)
  end

  defp possibly_qualified_column({:qualified_ident, _, col}), do: col

  defp possibly_qualified_column(v), do: v

  defp qualified_db_alias(aliaz), do: :"q_db_#{aliaz}"

  defp qualified_col_alias(db, col), do: :"#{db}.#{col}"

  defp call_func({c, r} = data, n, args) do
    {:ok, f} = StdLib.functions() |> Map.fetch(n)

    call = [r | data |> evaluate_exprs(args)] |> Call.new(c)

    {c, f.(call)}
  end

  defp evaluate_exprs(data, exprs) do
    exprs
    |> Enum.map(&interpret_expr(data, &1))
    |> Enum.map(&elem(&1, 1))
  end

  defp dump_register({c, nil}), do: {c, nil}

  defp dump_register({c, s}) do
    c =
      Memory.all(s)
      |> Enum.reduce(c, fn {k, v}, c -> Memory.store(c, k, v) end)

    {c, s}
  end

  defp dump_register(data), do: data
end
