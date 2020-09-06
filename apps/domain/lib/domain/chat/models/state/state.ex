defmodule Chat.State do
  defstruct question: nil,
            scenarios: [],
            processes: [],
            variables: %{}

  def new(question, scenarios, processes, variables \\ %{}) do
    %__MODULE__{
      question: question,
      scenarios: scenarios,
      processes: processes,
      variables: variables
    }
  end

  def scenario(%__MODULE__{scenarios: [s | _]}), do: s

  def process(%__MODULE__{processes: [p | _]}), do: p

  def fetch_variables(%__MODULE__{variables: v}, vars) do
    {m, _} = Map.split(v, vars)
    m
  end

  def set_var(%__MODULE__{variables: v} = s, n, i) do
    %__MODULE__{s | variables: Map.put(v, n, i)}
  end

  def delete_var(%__MODULE__{variables: v} = s, n) do
    %__MODULE__{s | variables: Map.delete(v, n)}
  end
end
