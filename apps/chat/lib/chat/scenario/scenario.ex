defmodule Chat.Scenario do
  @moduledoc """
  Scenario
  """

  use TypedStruct

  typedstruct do
    field(:id, atom(), enforce: true)
    field(:entry, atom(), enforce: true)
    field(:actions, map(), enforce: true, default: Map.new())
    field(:processes, map(), enforce: true, default: Map.new())
  end

  @spec new(any, any, any, any) :: Chat.Scenario.t()
  def new(id, entry, actions \\ %{}, processes \\ %{}) do
    %__MODULE__{
      id: id,
      entry: entry,
      actions: actions,
      processes: processes
    }
  end

  def entry(%__MODULE__{entry: e, processes: ps}) do
    Map.fetch(ps, e)
  end

  def action(%__MODULE__{actions: as}, p) do
    Map.fetch(as, p)
  end

  def process(%__MODULE__{processes: ps}, p) do
    Map.fetch(ps, p)
  end
end

defimpl Enumerable, for: Chat.Scenario do
  alias Chat.Scenario

  def count(%Scenario{actions: as, processes: ps}) do
    {:ok, map_size(as) + map_size(ps)}
  end

  def slice(_) do
    {:error, __MODULE__}
  end

  def member?(_, _) do
    {:error, __MODULE__}
  end

  def reduce(%Scenario{actions: as, processes: ps} = s, acc, fun) do
    as = :maps.to_list(as)
    ps = :maps.to_list(ps)

    reduce_scenario(
      %Scenario{s | actions: as, processes: ps},
      acc,
      fun
    )
  end

  defp reduce_scenario(%Scenario{}, {:halt, acc}, _), do: {:halted, acc}

  defp reduce_scenario(%Scenario{} = s, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce_scenario(s, &1, fun)}

  defp reduce_scenario(
         %Scenario{
           actions: [],
           processes: []
         },
         {:cont, acc},
         _
       ),
       do: {:done, acc}

  defp reduce_scenario(
         %Scenario{
           actions: [{a, _} | as]
         } = s,
         {:cont, acc},
         fun
       ) do
    reduce_scenario(%Scenario{s | actions: as}, fun.(a, acc), fun)
  end

  defp reduce_scenario(
         %Scenario{
           actions: [],
           processes: [{_, p} | ps]
         } = s,
         {:cont, acc},
         fun
       ) do
    reduce_scenario(%Scenario{s | processes: ps}, fun.(p, acc), fun)
  end
end
