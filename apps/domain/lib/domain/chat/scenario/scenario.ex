defmodule Chat.Scenario do
  @keys ~w[id actions processes]a

  @enforce_keys @keys

  defstruct id: nil,
            actions: %{},
            processes: %{}

  def new(id, actions \\ %{}, processes \\ %{}) do
    %__MODULE__{
      id: id,
      actions: actions,
      processes: processes,
    }
  end

  def action(%__MODULE__{actions: as}, p) do
    Map.get(as, p)
  end
end
