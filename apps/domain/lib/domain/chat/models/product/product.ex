defmodule Chat.Product do
  @enforce_keys [:id, :name, :directions, :explanation, :image]

  defstruct id: nil,
            name: nil,
            directions: nil,
            explanation: nil,
            image: nil
end

defimpl String.Chars, for: Chat.Product do
  def to_string(%Chat.Product{id: id}) do
    "%Product{id: #{id}}"
  end
end
