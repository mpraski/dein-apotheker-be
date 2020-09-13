defmodule Chat.Scenario.Answer do
  alias Chat.Scenario.Text

  @enforce_keys ~w[id text action]a

  defstruct id: nil,
            text: nil,
            action: nil,
            output: nil

  def new(id, text, action, output) do
    %__MODULE__{
      id: id,
      text: Text.new(text),
      action: action,
      output: output
    }
  end
end
