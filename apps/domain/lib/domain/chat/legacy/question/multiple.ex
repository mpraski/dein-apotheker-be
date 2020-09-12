defmodule Chat.Legacy.Question.Multiple do
  @enforce_keys [:id, :answers, :decisions]

  defstruct id: nil,
            answers: [],
            decisions: [],
            load_scenarios: false
end

defimpl String.Chars, for: Chat.Legacy.Question.Multiple do
  def to_string(%Chat.Legacy.Question.Multiple{id: id}) do
    "%Question.Multiple{id: #{id}}"
  end
end
