defmodule Api.User do
  use TypedStruct

  typedstruct do
    field(:id, binary(), enforce: true)
  end

  def generate_id, do: UUID.uuid4()

  def new(id) do
    %__MODULE__{
      id: id
    }
  end
end
