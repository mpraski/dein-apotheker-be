defmodule Api.Question do
  @enforce_keys [:id, :input, :messages]

  defstruct(
    id: nil,
    input: nil,
    messages: nil
  )
end
