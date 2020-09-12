defmodule Chat.Legacy.Question.Prompt do
  @enforce_keys [:id]

  defstruct id: nil,
            leads_to: nil,
            jumps_to: nil,
            loads_scenario: nil,
            comments: []
end

defimpl String.Chars, for: Chat.Legacy.Question.Prompt do
  def to_string(%Chat.Legacy.Question.Prompt{id: id}) do
    "%Question.Prompt{id: #{id}}"
  end
end
