defmodule Chat.Scenario do
  @enforce_keys [:id, :start, :questions, :translations]

  defstruct(
    id: nil,
    start: nil,
    questions: [],
    translations: %{}
  )
end
