defmodule Api.User.Journeys do
  @cache :user_cache

  alias Api.User
  alias Chat.State

  defmodule Journey do
    use TypedStruct

    typedstruct do
      field(:user, User.t(), enforce: true)
      field(:states, list(State.t()), enforce: true)
    end

    def new(user, state) do
      %__MODULE__{
        user: user,
        states: [state]
      }
    end

    def add(%__MODULE__{states: ss} = j, %State{} = s) do
      %__MODULE__{j | states: [s | ss]}
    end
  end

  def spec do
    {ConCache,
     [
       name: @cache,
       ttl_check_interval: check_interval(),
       global_ttl: ttl()
     ]}
  end

  def get(user_id) do
    ConCache.get(@cache, user_id)
  end

  def progress(%User{id: id} = u, %State{} = s) do
    ConCache.update(@cache, id, fn
      nil -> {:ok, Journey.new(u, s)}
      journey -> {:ok, Journey.add(journey, s)}
    end)
  end

  def regress(%User{id: id}, steps) do
    ConCache.isolated(@cache, id, fn ->
      ConCache.update_existing(@cache, id, fn %Journey{states: states} = j ->
        a = max(length(states) - 1, steps)
        %Journey{j | states: Enum.drop(states, a)}
      end)

      ConCache.get(@cache, id)
    end)
  end

  def ttl do
    :timer.hours(24)
  end

  defp check_interval do
    :timer.minutes(30)
  end
end
