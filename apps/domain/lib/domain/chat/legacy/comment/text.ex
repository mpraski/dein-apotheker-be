defmodule Chat.Legacy.Comment.Text do
  @enforce_keys [:content]

  defstruct content: nil
end

defimpl String.Chars, for: Chat.Legacy.Comment.Text do
  def to_string(%Chat.Legacy.Comment.Text{content: content}) do
    "%Comment.Text{content: #{content}}"
  end
end
