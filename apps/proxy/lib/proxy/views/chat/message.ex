defmodule Proxy.Views.Chat.Message do
  @moduledoc """
  Message holds information required to render
  the current message
  """

  use TypedStruct

  alias Proxy.Views.Chat.{Popup}

  @derive Jason.Encoder

  typedstruct do
    field(:question, atom(), enforce: true)
    field(:type, atom(), enforce: true)
    field(:text, binary(), enforce: true, default: "")
    field(:input, any(), enforce: true, default: nil)
    field(:popup, Popup.t(), default: nil)
  end

  def new(question, type, text, input \\ nil) do
    %__MODULE__{
      question: question,
      type: decode_type(type),
      text: text,
      input: input
    }
  end

  def with_popup(%__MODULE__{} = m, nil), do: m

  def with_popup(%__MODULE__{} = m, %Popup{} = p) do
    %__MODULE__{m | popup: p}
  end

  def decode_type(:Q), do: :question
  def decode_type(:N), do: :list
  def decode_type(:PN), do: :product_list
  def decode_type(:P), do: :product
  def decode_type(:C), do: :comment
  def decode_type(:F), do: :free
  def decode_type(:D), do: :date
end
