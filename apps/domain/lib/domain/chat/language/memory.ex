defprotocol Chat.Language.Memory do
  @spec store(__MODULE__.t(), atom(), any()) :: __MODULE__.t()
  def store(impl, name, value)

  @spec load(__MODULE__.t(), atom()) :: {:ok, any()} | :error
  def load(impl, name)

  @spec load_many(__MODULE__.t(), list(atom())) :: map()
  def load_many(impl, names)

  @spec delete(__MODULE__.t(), atom()) :: __MODULE__.t()
  def delete(impl, name)

  @spec all(__MODULE__.t()) :: map()
  def all(impl)
end

defimpl Chat.Language.Memory, for: Any do
  def store(impl, _, _), do: impl

  def load(_, _), do: :error

  def load_many(_, _), do: Map.new()

  def delete(impl, _), do: impl

  def all(_), do: Map.new()
end
