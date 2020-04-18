defmodule Chat.Question.Prompt do
  @enforce_keys [:id]

  defstruct(
    id: nil,
    leads_to: nil
  )
end
