defmodule Chat.Answer.Multiple do
  defstruct(
    case: nil,
    leads_to: nil,
    jumps_to: nil,
    loads_scenario: nil,
    comments: []
  )
end
