defmodule Chat.Language.Context do
  @moduledoc """
  Context carries certain information needed
  to execute programs
  """

  use TypedStruct

  typedstruct do
    field(:memory, map(), default: Map.new())
  end

  def new() do
    %__MODULE__{
      memory: Map.new()
    }
  end

  defdelegate scenario(id), to: Chat

  defdelegate database(id), to: Chat
end

defimpl Chat.Language.Memory, for: Chat.Language.Context do
  alias Chat.Language.Context

  def store(%Context{} = c, nil, _), do: c

  def store(%Context{memory: m} = c, n, i) do
    %Context{c | memory: Map.put(m, n, i)}
  end

  def load(%Context{memory: m}, n) do
    Map.fetch(m, n)
  end

  def load_many(%Context{memory: m}, ns) do
    {m, _} = Map.split(m, ns)
    m
  end

  def delete(%Context{memory: v} = c, n) do
    %Context{c | memory: Map.delete(v, n)}
  end

  def all(%Context{memory: v}), do: v
end
