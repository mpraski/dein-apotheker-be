defmodule Chat.Comment.Text do
  @enforce_keys [:content]

  defstruct content: nil
end

defimpl String.Chars, for: Chat.Comment.Text do
  def to_string(%Chat.Comment.Text{content: content}) do
    "%Comment.Text{content: #{content}}"
  end
end
