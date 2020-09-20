defmodule Chat.Language.Interpreter do
  alias Chat.State
  alias Chat.Database
  alias Chat.Language.StdLib
  alias Chat.Language.StdLib.Call

  defmodule Context do
    use TypedStruct

    typedstruct do
      field(:scenarios, map(), enforce: true)
      field(:databases, map(), enforce: true)
      field(:memory, map(), default: Map.new())
    end

    def new(scenarios, databases) do
      %__MODULE__{
        scenarios: scenarios,
        databases: databases
      }
    end

    def get_var(%__MODULE__{memory: m}, n) do
      Map.fetch(m, n)
    end

    def set_var(%__MODULE__{} = c, nil, _), do: c

    def set_var(%__MODULE__{memory: m} = c, n, i) do
      %__MODULE__{c | memory: Map.put(m, n, i)}
    end

    def set_vars(%__MODULE__{memory: m} = c, vars) do
      %__MODULE__{c | memory: Map.merge(m, vars)}
    end

    def delete_var(%__MODULE__{memory: v} = c, n) do
      %__MODULE__{c | memory: Map.delete(v, n)}
    end
  end

  def interpret(program) do
    fn %Context{} = c, r ->
      {_, r} = {c, r} |> interpret_exprs(program)
      r
    end
  end

  defp interpret_exprs(data, exprs) do
    Enum.reduce(exprs, data, &interpret_expr(&2, &1))
  end

  defp interpret_expr(data, {:lif, a, b, d}) do
    {_, p} = data |> interpret_expr(a)

    if p do
      data |> interpret_exprs(b)
    else
      data |> interpret_exprs(d)
    end
  end

  defp interpret_expr(data, {:unless, a, b, c}) do
    data |> interpret_expr({:lif, a, c, b})
  end

  defp interpret_expr({_, s} = data, {:for, {:var, i}, {:var, v}, exprs}) do
    case State.get_var(s, v) do
      {:ok, items} ->
        {c, s} =
          Enum.reduce(items, data, fn a, {c, s} ->
            {Context.set_var(c, i, a), s} |> interpret_exprs(exprs)
          end)

        {Context.delete_var(c, i), s}

      _ ->
        data
    end
  end

  defp interpret_expr(data, {:call, {:ident, f}, args}) do
    data |> call_func(f, args)
  end

  defp interpret_expr({c, r} = d, {:assign, {:var, v}, expr}) do
    {_, e} = d |> interpret_expr(expr)
    {Context.set_var(c, v, e), r}
  end

  defp interpret_expr({c, _}, {:ident, i}) when is_atom(i), do: {c, i}

  defp interpret_expr(data, {:with, i, w}) do
    {interpret_expr(data, i), Enum.map(w, &interpret_expr(data, &1))}
  end

  defp interpret_expr(
         {%Context{memory: m} = c, %State{} = s},
         {:var, v}
       )
       when is_atom(v),
       do: {c, Map.merge(State.all_vars(s), m) |> Map.get(v)}

  defp interpret_expr(
         {%Context{memory: m} = c, _},
         {:var, v}
       )
       when is_atom(v),
       do: {c, Map.get(m, v)}

  defp interpret_expr({c, _}, {:string, s}) when is_list(s), do: {c, to_string(s)}

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

  defp interpret_expr(data, {:select, columns, database, [], nil}) do
    data
    |> dump_state()
    |> interpret_from(database)
    |> interpret_select(columns)
  end

  defp interpret_expr(data, {:select, columns, database, [], where}) do
    data
    |> dump_state()
    |> interpret_from(database)
    |> interpret_select(columns)
    |> interpret_where(where)
  end

  defp interpret_expr(data, {:select, columns, database, joins, nil}) do
    db =
      data
      |> dump_state()
      |> interpret_from(database)

    joins
    |> Enum.reduce(db, &interpret_join(&2, &1))
    |> interpret_select(columns)
  end

  defp interpret_expr(data, {:select, columns, database, joins, where}) do
    db =
      data
      |> dump_state()
      |> interpret_from(database)

    joins
    |> Enum.reduce(db, &interpret_join(&2, &1))
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

  defp interpret_from({%Context{databases: dbs}, _} = d, name) do
    {c, name} = d |> interpret_expr(name)

    case name do
      {:qualified_db, name, aliaz} ->
        {:ok, db} = Map.fetch(dbs, name)
        {Context.set_var(c, qualified_db_alias(aliaz), name), db}

      name ->
        {:ok, db} = Map.fetch(dbs, name)
        {c, db}
    end
  end

  defp interpret_join({%Context{databases: dbs}, _} = d, {:join, name, on_expr}) do
    {c, {:qualified_db, name, aliaz}} = d |> interpret_expr(name)
    c = Context.set_var(c, qualified_db_alias(aliaz), name)

    {:ok, db} = Map.fetch(dbs, name)

    {c, db}
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

    {:ok, v} = Keyword.fetch(r, normalize_column(v))

    v == i
  end

  defp evaluate_where_expr(data, {:not_equals, v, i}) do
    data |> evaluate_where_expr({:equals, v, i}) |> Kernel.not()
  end

  defp evaluate_on_expr(data, {:lor, a, b}) do
    a = data |> evaluate_where_expr(a)
    b = data |> evaluate_where_expr(b)

    a || b
  end

  defp evaluate_on_expr(data, {:land, a, b}) do
    a = data |> evaluate_where_expr(a)
    b = data |> evaluate_where_expr(b)

    a && b
  end

  defp evaluate_on_expr({_, r} = d, {:equals, v, i}) do
    {:qualified_ident, db1, col1} = d |> interpret_expr(v)
    {:qualified_ident, db2, col2} = d |> interpret_expr(i)

    {:ok, v} = Keyword.fetch(r, normalize_column(v))

    v == i
  end

  defp evaluate_on_expr(data, {:not_equals, v, i}) do
    data |> evaluate_where_expr({:equals, v, i}) |> Kernel.not()
  end

  defp normalize_column(v) when is_atom(v), do: v

  defp normalize_column(v) when is_binary(v), do: String.to_existing_atom(v)

  defp normalize_column({:qualified_ident, db, col}) do
    qualified_col_alias(db, col)
  end

  defp qualified_db_alias(aliaz), do: :"q_db_#{aliaz}"

  defp qualified_col_alias(db, col), do: :"#{db}.#{col}"

  defp call_func({c, r} = data, n, args) do
    {:ok, f} = Map.fetch(StdLib.functions(), n)

    call = [r | data |> evaluate_exprs(args)] |> Call.new(c)

    {c, f.(call)}
  end

  defp evaluate_exprs(data, exprs) do
    exprs
    |> Enum.map(&interpret_expr(data, &1))
    |> Enum.map(&elem(&1, 1))
  end

  defp dump_state({%Context{} = c, %State{} = s}) do
    {Context.set_vars(c, State.all_vars(s)), s}
  end

  defp dump_state(data), do: data
end
