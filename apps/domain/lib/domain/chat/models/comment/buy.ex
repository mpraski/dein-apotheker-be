defmodule Chat.Comment.Buy do
  @enforce_keys [:name, :image, :price]

  defstruct name: nil,
            image: nil,
            price: nil
end
