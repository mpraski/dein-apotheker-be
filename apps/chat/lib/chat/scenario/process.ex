defmodule Chat.Scenario.Process do
  @moduledoc """
  Scenario process
  """

  use TypedStruct

  typedstruct do
    field(:id, atom(), enforce: true)
    field(:entry, atom(), enforce: true)
    field(:questions, map(), enforce: true, default: Map.new())
  end

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

defimpl Enumerable, for: Chat.Scenario.Process do
  alias Chat.Scenario.Process

  def count(%Process{questions: qs}) do
    {:ok, map_size(qs)}
  end

  def slice(_) do
    {:error, __MODULE__}
  end

  def member?(%Process{questions: qs}, q) do
    {:ok, Map.has_key?(qs, q)}
  end

  def reduce(%Process{questions: qs} = p, acc, fun) do
    qs = :maps.to_list(qs)

    reduce_process(
      %Process{p | questions: qs},
      acc,
      fun
    )
  end

  defp reduce_process(%Process{}, {:halt, acc}, _), do: {:halted, acc}

  defp reduce_process(%Process{} = p, {:suspend, acc}, fun),
    do: {:suspended, acc, &reduce_process(p, &1, fun)}

  defp reduce_process(
         %Process{
           questions: []
         },
         {:cont, acc},
         _
       ),
       do: {:done, acc}

  defp reduce_process(
         %Process{
           questions: [{_, q} | qs]
         } = p,
         {:cont, acc},
         fun
       ) do
    reduce_process(%Process{p | questions: qs}, fun.(q, acc), fun)
  end
end
