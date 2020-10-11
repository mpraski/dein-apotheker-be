defmodule Account.User do
  @moduledoc """
  User represents a single user
  """

  use TypedStruct

  typedstruct do
    field(:id, binary(), enforce: true)
  end

  def new(id \\ UUID.uuid4()) do
    %__MODULE__{
      id: id
    }
  end
end
