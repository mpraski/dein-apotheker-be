defmodule Proxy.Session do
  use TypedStruct

  alias Chat.State

  typedstruct do
    field(:user_id, binary(), enforce: true)
    field(:states, map(), enforce: true)
    field(:current_state, binary(), enforce: true)
  end

  def new(user_id, %State{id: id} = state) do
    %__MODULE__{
      user_id: user_id,
      states: %{id => state},
      current_state: id
    }
  end

  def add(%__MODULE__{states: ss} = j, %State{id: id} = s) do
    %__MODULE__{j | states: Map.put(ss, id, s), current_state: id}
  end

  def fresh(%__MODULE__{states: ss}), do: Enum.count(ss) == 1

  def current_state(%__MODULE__{states: ss, current_state: id}) do
    Map.get(ss, id)
  end
end
