defmodule Chat.Contextual do
  @enforce_keys [:context, :data]

  defstruct(
    context: nil,
    data: nil
  )
end
