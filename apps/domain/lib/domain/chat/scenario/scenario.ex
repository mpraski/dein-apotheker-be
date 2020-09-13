defmodule Chat.Scenario do
  @enforce_keys ~w[id entry actions processes]a

  defstruct id: nil,
            entry: nil,
            actions: %{},
            processes: %{}

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
