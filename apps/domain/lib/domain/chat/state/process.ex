defmodule Chat.State.Process do
  @keys ~w[id variables]a

  @enforce_keys @keys

  defstruct id: nil,
            variables: %{}

  def new(id, vars \\ %{}) do
    %__MODULE__{
      id: id,
      variables: vars,
    }
  end
end
