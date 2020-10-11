defmodule Chat.State.Process do
  @moduledoc """
  Process to be queued in state
  """

  use TypedStruct

  typedstruct do
    field(:id, atom(), enforce: true)
    field(:variables, map(), enforce: true, default: Map.new())
  end

  def new(id, vars \\ %{}) do
    %__MODULE__{
      id: id,
      variables: vars
    }
  end
end
