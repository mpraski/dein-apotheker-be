defmodule Chat.Scenario.Question do
  alias Chat.Scenario.Answer

  @types ~w[Q N P C F]a

  @enforce_keys ~w[id type text action answers]a

  defstruct id: nil,
            type: nil,
            query: nil,
            text: nil,
            action: nil,
            output: nil,
            answers: []

  def new(id, type, query, text, action, output) when type in @types do
    %__MODULE__{
      id: id,
      type: type,
      query: query,
      text: text,
      action: action,
      output: output,
      answers: []
    }
  end

  def add_answer(%Answer{} = a, %__MODULE__{answers: as} = q) do
    %__MODULE__{q | answers: as ++ [a]}
  end
end
