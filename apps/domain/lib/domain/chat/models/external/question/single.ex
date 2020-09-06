defmodule Chat.Question.Single do
  @enforce_keys [:id, :answers]

  defstruct id: nil, answers: nil
end

defimpl String.Chars, for: Chat.Question.Single do
  def to_string(%Chat.Question.Single{id: id}) do
    "%Question.Single{id: #{id}}"
  end
end
