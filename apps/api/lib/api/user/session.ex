defmodule Api.User.Session do
  use TypedStruct

  alias Chat.State

  typedstruct do
    field(:user, User.t(), enforce: true)
    field(:states, map(), enforce: true)
  end

  def new(user, %State{id: id} = state) do
    %__MODULE__{
      user: user,
      states: %{id => state}
    }
  end

  def add(%__MODULE__{states: ss} = j, %State{id: id} = s) do
    %__MODULE__{j | states: Map.put(ss, id, s)}
  end
end
