defmodule Api.User.Sessions do
  @cache :user_cache

  alias Api.User
  alias Api.User.Session
  alias Chat.State

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

  def add(%User{id: id} = u, %State{} = s) do
    ConCache.update(@cache, id, fn
      nil -> {:ok, Session.new(u, s)}
      session -> {:ok, session |> Session.add(s)}
    end)
  end

  def ttl do
    :timer.hours(24)
  end

  defp check_interval do
    :timer.minutes(30)
  end
end
