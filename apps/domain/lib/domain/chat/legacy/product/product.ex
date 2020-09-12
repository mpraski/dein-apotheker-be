defmodule Chat.Legacy.Product do
  @enforce_keys [:id, :name, :directions, :explanation, :image]

  defstruct id: nil,
            name: nil,
            directions: nil,
            explanation: nil,
            image: nil
end

defimpl String.Chars, for: Chat.Legacy.Product do
  def to_string(%Chat.Legacy.Product{id: id}) do
    "%Product{id: #{id}}"
  end
end
