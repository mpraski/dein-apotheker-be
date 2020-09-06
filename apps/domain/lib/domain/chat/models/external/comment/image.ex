defmodule Chat.Comment.Image do
  @enforce_keys [:image, :content]

  defstruct image: nil, content: nil
end

defimpl String.Chars, for: Chat.Comment.Image do
  def to_string(%Chat.Comment.Image{content: content}) do
    "%Comment.Image{content: #{content}}"
  end
end
