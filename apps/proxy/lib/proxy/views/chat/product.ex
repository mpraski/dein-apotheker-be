defmodule Proxy.Views.Chat.Product do
  @moduledoc """
  Product holds information required to render a product
  """

  use TypedStruct

  @derive Jason.Encoder

  typedstruct do
    field(:id, binary(), enforce: true)
    field(:name, binary(), enforce: true)
    field(:image, binary(), enforce: true)
  end

  def new(id, name, image) do
    %__MODULE__{
      id: id,
      name: name,
      image: image
    }
  end
end
