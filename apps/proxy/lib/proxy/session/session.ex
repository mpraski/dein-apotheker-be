defmodule Proxy.Session do
  use TypedStruct

  alias Chat.State

  typedstruct do
    field(:user_id, binary(), enforce: true)
    field(:states, map(), enforce: true)
  end

  def new(user_id) do
    %__MODULE__{
      user_id: user_id,
      states: %{}
    }
  end

  def add(%__MODULE__{states: ss} = j, %State{id: id} = s) do
    %__MODULE__{j | states: Map.put(ss, id, s)}
  end

  def fetch(%__MODULE__{states: ss}, state_id) do
    Map.fetch(ss, state_id)
  end
end
