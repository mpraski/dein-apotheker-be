defmodule Chat.State do
  alias Chat.State.{Process, Message}

  use TypedStruct

  @derive Jason.Encoder

  typedstruct do
    field(:question, atom(), enforce: true)
    field(:message, Message.t(), default: nil)
    field(:scenarios, list(atom()), enforce: true, default: [])
    field(:processes, list(Process.t()), enforce: true, default: [])
    field(:variables, map(), enforce: true, default: Map.new())
  end

  defmodule Failure do
    defexception message: "State failure"
  end

  def new(question, scenarios, processes, variables \\ %{}) do
    %__MODULE__{
      question: question,
      scenarios: scenarios,
      processes: processes,
      variables: variables,
      message: nil
    }
  end

  def scenario(%__MODULE__{scenarios: [s | _]}), do: s

  def scenario(%__MODULE__{scenarios: []}) do
    raise Failure, message: "No scenarios on stack"
  end

  def process(%__MODULE__{processes: [p | _]}), do: p

  def process(%__MODULE__{processes: []}) do
    raise Failure, message: "No processes on stack"
  end

  def fetch_variables(_, nil), do: Map.new()

  def fetch_variables(%__MODULE__{variables: v}, vars) do
    {m, _} = Map.split(v, vars)
    m
  end

  def all_vars(%__MODULE__{variables: v, processes: []}), do: v

  def all_vars(%__MODULE__{
        variables: v,
        processes: [%Process{variables: pv} | _]
      }) do
    Map.merge(v, pv)
  end

  def get_var(%__MODULE__{} = s, v) do
    __MODULE__.all_vars(s) |> Map.fetch(v)
  end

  def set_var(%__MODULE__{} = s, nil, _), do: s

  def set_var(%__MODULE__{variables: v} = s, n, i) do
    %__MODULE__{s | variables: Map.put(v, n, i)}
  end
end

defimpl String.Chars, for: Chat.State do
  alias Chat.State

  def to_string(%State{}), do: "User State"
end
