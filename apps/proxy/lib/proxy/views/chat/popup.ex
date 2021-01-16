defmodule Proxy.Views.Chat.Popup do
  @moduledoc """
  Popup holds information required to render a popup
  """

  use TypedStruct

  @derive Jason.Encoder

  typedstruct do
    field(:hint, binary(), enforce: true)
    field(:content, binary(), enforce: true)
  end

  def new(hint, content) do
    %__MODULE__{
      hint: hint,
      content: content
    }
  end
end
