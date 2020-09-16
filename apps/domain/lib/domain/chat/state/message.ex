defmodule Chat.State.Message do
  @enforce_keys ~w[type text data]a

  @derive Jason.Encoder
  defstruct type: nil,
            text: "",
            data: %{}

  def new(type, text, data \\ %{}) do
    %__MODULE__{
      type: decode_type(type),
      text: text,
      data: data
    }
  end

  def decode_type(:Q), do: :question
  def decode_type(:N), do: :list
  def decode_type(:P), do: :product
  def decode_type(:C), do: :comment
  def decode_type(:F), do: :free
end
