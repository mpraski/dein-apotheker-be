defmodule Chat.Question.Single do
  @enforce_keys [:id, :answers]

  defstruct(
    id: nil,
    answers: nil
  )
end
