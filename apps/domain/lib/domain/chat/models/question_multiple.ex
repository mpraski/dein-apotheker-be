defmodule Chat.Question.Multiple do
  @enforce_keys [:id, :answers, :decisions]

  defstruct(
    id: nil,
    answers: [],
    decisions: []
  )
end
