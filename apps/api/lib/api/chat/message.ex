defmodule Api.Chat.Message do
  use TypedStruct

  @derive Jason.Encoder

  typedstruct do
    field(:question, atom(), enforce: true)
    field(:type, atom(), enforce: true)
    field(:text, binary(), enforce: true, default: "")
    field(:input, any(), enforce: true, default: nil)
  end

  def new(question, type, text, input \\ nil) do
    %__MODULE__{
      question: question,
      type: decode_type(type),
      text: text,
      input: input
    }
  end

  def decode_type(:Q), do: :question
  def decode_type(:N), do: :list
  def decode_type(:PN), do: :product_list
  def decode_type(:P), do: :product
  def decode_type(:C), do: :comment
  def decode_type(:F), do: :free
end
