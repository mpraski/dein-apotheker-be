defmodule Chat.Legacy.Comment.Image do
  @enforce_keys [:image, :content]

  defstruct image: nil, content: nil
end

defimpl String.Chars, for: Chat.Legacy.Comment.Image do
  def to_string(%Chat.Legacy.Comment.Image{content: content}) do
    "%Comment.Image{content: #{content}}"
  end
end
