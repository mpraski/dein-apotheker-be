defmodule Chat.Question.Prompt do
  @enforce_keys [:id]

  defstruct id: nil,
            leads_to: nil,
            jumps_to: nil,
            loads_scenario: nil,
            comments: []
end
