defmodule Chat.Comment do
  @enforce_keys [:type]

  defstruct(
    type: nil,
    content: nil,
    image: nil
  )
end
