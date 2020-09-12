defmodule Chat.Scenario.Process do
  @keys ~w[id questions]a

  @enforce_keys @keys

  defstruct id: nil,
            questions: %{}

  def new(id, questions \\ %{}) do
    %__MODULE__{
      id: id,
      questions: questions
    }
  end

  def question(%__MODULE__{questions: qs}, q) do
    Map.get(qs, q)
  end
end
