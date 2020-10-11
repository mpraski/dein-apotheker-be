defmodule Proxy.Views.Chat.State do
  @moduledoc """
  State is the representation of chat state
  """

  use TypedStruct

  alias Proxy.Views.Chat.{Message, Product}

  @derive Jason.Encoder

  typedstruct do
    field(:id, binary(), enforce: true)
    field(:message, Message.t(), enforce: true)
    field(:cart, list(Product.t()), enforce: true)
  end

  def new(id, message, cart \\ []) do
    %__MODULE__{
      id: id,
      message: message,
      cart: cart
    }
  end
end
