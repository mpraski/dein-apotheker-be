defmodule Chat.Question.Prompt do
  @enforce_keys [:id]

  defstruct id: nil,
            leads_to: nil,
            jumps_to: nil,
            loads_scenario: nil,
            comments: []
end

defimpl String.Chars, for: Chat.Question.Prompt do
  def to_string(%Chat.Question.Prompt{id: id}) do
    "%Question.Prompt{id: #{id}}"
  end
end
