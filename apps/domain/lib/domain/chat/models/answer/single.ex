defmodule Chat.Answer.Single do
  @enforce_keys [:id]

  defstruct(
    id: nil,
    leads_to: nil,
    jumps_to: nil,
    loads_scenario: nil,
    comments: []
  )
end