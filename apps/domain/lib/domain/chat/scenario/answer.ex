defmodule Chat.Scenario.Answer do
  @enforce_keys ~w[id text action]a

  defstruct id: nil,
            text: nil,
            action: nil,
            output: nil

  def new(id, text, action, output) do
    %__MODULE__{
      id: id,
      text: text,
      action: action,
      output: output
    }
  end
end
