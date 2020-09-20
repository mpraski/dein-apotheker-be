defmodule Chat.Language.Verifier.Result do
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question}

  defstruct processes: %{},
            declarations: %{},
            errors: [],
            ast: nil

  def new(%Scenario{} = s, ast) do
    processes =
      s
      |> Enum.map(&extract_process_id/1)
      |> Enum.into(MapSet.new())

    declarations =
      s
      |> Enum.filter(&filter_process/1)
      |> Enum.flat_map(&Enum.to_list/1)
      |> Enum.map(fn %Question{output: o} -> o end)
      |> Enum.filter(&(!is_nil(&1)))
      |> Enum.into(MapSet.new())

    %__MODULE__{
      processes: processes,
      declarations: declarations,
      ast: ast
    }
  end

  def print(%__MODULE__{errors: es, ast: ast}) do
    es |> Enum.map(&(&1 <> " in " <> inspect(ast)))
  end

  def log(%__MODULE__{errors: es} = r, msg, cnd) do
    if cnd.(r) do
      %__MODULE__{r | errors: [msg | es]}
    else
      r
    end
  end

  def has_process?(%__MODULE__{processes: ps}, p) do
    Enum.member?(ps, p)
  end

  def declared?(%__MODULE__{declarations: ds}, d) do
    Enum.member?(ds, d)
  end

  def declare(%__MODULE__{declarations: ds} = r, d) do
    %__MODULE__{r | declarations: MapSet.put(ds, d)}
  end

  def undeclare(%__MODULE__{declarations: ds} = r, d) do
    %__MODULE__{r | declarations: MapSet.delete(ds, d)}
  end

  defp filter_process(%Process{}), do: true

  defp filter_process(_), do: false

  defp extract_process_id(p) when is_atom(p), do: p

  defp extract_process_id(%Process{id: id}), do: id
end
