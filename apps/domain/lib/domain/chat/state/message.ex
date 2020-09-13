defmodule Chat.State.Message do
  @types ~w[question text image product list]a

  @enforce_keys ~w[type text data]a

  defstruct type: nil,
            text: "",
            data: %{}

  def new(type, text, data \\ %{}) when type in @types do
    %__MODULE__{
      type: type,
      text: text,
      data: data
    }
  end
end
