defmodule Chat.Comment.Image do
  @enforce_keys [:image, :content]

  defstruct(
    image: nil,
    content: nil
  )
end
