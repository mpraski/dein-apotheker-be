defmodule Chat.Answer.Multiple do
  defstruct case: nil,
            leads_to: nil,
            jumps_to: nil,
            loads_scenario: nil,
            comments: []
end

defimpl String.Chars, for: Chat.Answer.Multiple do
  def to_string(%Chat.Answer.Multiple{case: c}) do
    "%Answer.Multiple{case: #{c}}"
  end
end
