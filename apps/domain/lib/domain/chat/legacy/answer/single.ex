defmodule Chat.Legacy.Answer.Single do
  @enforce_keys [:id]

  defstruct id: nil,
            leads_to: nil,
            jumps_to: nil,
            loads_scenario: nil,
            comments: []
end

defimpl String.Chars, for: Chat.Legacy.Answer.Single do
  def to_string(%Chat.Legacy.Answer.Single{id: id}) do
    "%Answer.Single{id: #{id}}"
  end
end
