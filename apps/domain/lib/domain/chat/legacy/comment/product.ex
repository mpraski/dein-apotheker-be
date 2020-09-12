defmodule Chat.Legacy.Comment.Product do
  @enforce_keys [:product]

  defstruct product: nil
end

defimpl String.Chars, for: Chat.Legacy.Comment.Product do
  def to_string(%Chat.Legacy.Comment.Product{product: product}) do
    "%Comment.Product{product: #{product}}"
  end
end
