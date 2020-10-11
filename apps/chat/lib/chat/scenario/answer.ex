defmodule Chat.Scenario.Answer do
  @moduledoc """
  Answer for a question
  """

  alias Chat.Scenario.Text

  use TypedStruct

  typedstruct do
    field(:id, atom(), enforce: true)
    field(:text, Text.t(), enforce: true)
    field(:action, (any(), any() -> any()), enforce: true)
    field(:output, atom())
  end

  def new(id, text, action, output) do
    %__MODULE__{
      id: id,
      text: Text.new(text),
      action: action,
      output: output
    }
  end
end
