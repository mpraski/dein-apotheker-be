defmodule Chat.Product do
  @enforce_keys [:id, :name, :directions, :explanation, :image]

  defstruct id: nil,
            name: nil,
            directions: nil,
            explanation: nil,
            image: nil
end
