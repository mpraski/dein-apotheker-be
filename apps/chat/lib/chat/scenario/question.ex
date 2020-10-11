defmodule Chat.Scenario.Question do
  alias Chat.Scenario.{Answer, Text}

  use TypedStruct

  typedstruct do
    field(:id, atom(), enforce: true)
    field(:type, atom(), enforce: true)
    field(:text, Text.t(), enforce: true)
    field(:action, (any(), any() -> any()), enforce: true)
    field(:answers, list(Answer.t()), enforce: true, default: [])
    field(:query, (any(), any() -> any()))
    field(:output, atom())
  end

  @types ~w[Q N P PN C F]a

  def new(id, type, query, text, action, output) when type in @types do
    %__MODULE__{
      id: id,
      type: type,
      query: query,
      text: Text.new(text || ""),
      action: action,
      output: output,
      answers: []
    }
  end

  def answer(%__MODULE__{answers: as}, a) do
    case Enum.find(as, fn %Answer{id: id} -> id == a end) do
      %Answer{} = a -> {:ok, a}
      _ -> :error
    end
  end

  def add_answer(%Answer{} = a, %__MODULE__{answers: as} = q) do
    %__MODULE__{q | answers: as ++ [a]}
  end
end

defimpl Enumerable, for: Chat.Scenario.Question do
  alias Chat.Scenario.Question

  def count(%Question{answers: as}) do
    {:ok, length(as)}
  end

  def slice(_) do
    {:error, __MODULE__}
  end

  def member?(%Question{answers: as}, a) do
    {:ok, Enum.member?(as, a)}
  end

  def reduce(%Question{}, {:halt, acc}, _), do: {:halted, acc}

  def reduce(%Question{} = q, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce(q, &1, fun)}

  def reduce(
        %Question{
          answers: []
        },
        {:cont, acc},
        _
      ),
      do: {:done, acc}

  def reduce(
        %Question{
          answers: [a | as]
        } = q,
        {:cont, acc},
        fun
      ) do
    reduce(%Question{q | answers: as}, fun.(a, acc), fun)
  end
end
