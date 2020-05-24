defmodule Chat.Answer.Single do
  @enforce_keys [:id]

  defstruct id: nil,
            leads_to: nil,
            jumps_to: nil,
            loads_scenario: nil,
            comments: []
end

defimpl String.Chars, for: Chat.Answer.Single do
  def to_string(%Chat.Answer.Single{id: id}) do
    "%Answer.Single{id: #{id}}"
  end
end
