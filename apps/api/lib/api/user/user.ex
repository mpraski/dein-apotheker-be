defmodule Api.User do
  use TypedStruct

  alias Chat.State

  typedstruct do
    field(:id, binary(), enforce: true)
    field(:state, State.t(), enforce: true)
  end

  def generate_id, do: UUID.uuid4()

  def new(id, state) do
    %__MODULE__{
      id: id,
      state: state
    }
  end
end
