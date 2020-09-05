defmodule Chat.Process do
  alias __MODULE__

  @keys ~w[name variables]a

  @enforce_keys @keys

  defstruct name: nil,
            variables: %{}

  def new(name, vars \\ %{}) do
    %__MODULE__{
      name: name,
      variables: vars,
    }
  end
end
