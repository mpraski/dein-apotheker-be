defmodule Chat.Comment.Product do
  @enforce_keys [:product]

  defstruct product: nil
end

defimpl String.Chars, for: Chat.Comment.Product do
  def to_string(%Chat.Comment.Product{product: product}) do
    "%Comment.Product{product: #{product}}"
  end
end
