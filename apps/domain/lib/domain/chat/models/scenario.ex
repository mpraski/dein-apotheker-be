defmodule Chat.Scenario do
  @enforce_keys [:id, :questions, :translations]

  defstruct(
    id: nil,
    questions: [],
    translations: %{}
  )
end
