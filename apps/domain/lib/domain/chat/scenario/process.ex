defmodule Chat.Scenario.Process do
  @enforce_keys ~w[id entry questions]a

  defstruct id: nil,
            entry: nil,
            questions: %{}

  def new(id, entry, questions \\ %{}) do
    %__MODULE__{
      id: id,
      entry: entry,
      questions: questions
    }
  end

  def entry(%__MODULE__{entry: e, questions: qs}) do
    Map.fetch(qs, e)
  end

  def question(%__MODULE__{questions: qs}, q) do
    Map.fetch(qs, q)
  end
end
