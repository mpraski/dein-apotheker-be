defmodule Chat.State.Process do
  @enforce_keys ~w[id variables]a

  @derive Jason.Encoder
  defstruct id: nil, variables: %{}

  def new(id, vars \\ %{}) do
    %__MODULE__{
      id: id,
      variables: vars
    }
  end
end
