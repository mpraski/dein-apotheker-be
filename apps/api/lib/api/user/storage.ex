defmodule Api.User.Storage do
  @cache :user_cache

  alias Api.User
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

  def put(%User{id: id, state: s} = u) do
    ConCache.put(@cache, id, %User{u | state: %State{s | message: nil}})
  end

  def ttl do
    :timer.hours(24)
  end

  defp check_interval do
    :timer.minutes(30)
  end
end
