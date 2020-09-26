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
end

defimpl Chat.Language.Memory, for: Chat.State do
  alias Chat.State
  alias Chat.State.Process

  def store(%State{} = s, nil, _), do: s

  def store(%State{variables: v} = s, n, i) do
    %State{s | variables: Map.put(v, n, i)}
  end

  def load(%State{} = s, v) do
    Chat.Language.Memory.all(s) |> Map.fetch(v)
  end

  def load_many(%State{variables: v}, vars) do
    {v, _} = Map.split(v, vars)
    v
  end

  def delete(%State{variables: v} = s, n) do
    %State{s | variables: Map.delete(v, n)}
  end

  def all(%State{variables: v, processes: []}), do: v

  def all(%State{
        variables: v,
        processes: [%Process{variables: pv} | _]
      }) do
    Map.merge(v, pv)
  end
end

defimpl String.Chars, for: Chat.State do
  alias Chat.State

  def to_string(%State{}), do: "User State"
end
