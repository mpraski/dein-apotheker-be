defmodule Chat.Legacy.Question.Message do
  @enforce_keys [:id, :leads_to, :comments]

  defstruct id: nil,
            leads_to: nil,
            comments: []
end

defimpl String.Chars, for: Chat.Legacy.Question.Message do
  def to_string(%Chat.Legacy.Question.Message{id: id}) do
    "%Question.Message{id: #{id}}"
  end
end
