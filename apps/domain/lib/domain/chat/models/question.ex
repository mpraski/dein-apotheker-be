defmodule Chat.Question do
  @enforce_keys [:id, :type, :answers]

  defstruct(
    id: nil,
    type: nil,
    answers: nil
  )
end
