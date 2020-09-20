defmodule Chat.State.Message do
  use TypedStruct

  @derive Jason.Encoder

  typedstruct do
    field(:type, atom(), enforce: true)
    field(:text, binary(), enforce: true, default: "")
    field(:input, map(), enforce: true, default: Map.new())
  end

  def new(type, text, input \\ %{}) do
    %__MODULE__{
      type: decode_type(type),
      text: text,
      input: input
    }
  end

  def decode_type(:Q), do: :question
  def decode_type(:N), do: :list
  def decode_type(:P), do: :product
  def decode_type(:C), do: :comment
  def decode_type(:F), do: :free
end
