defmodule Proxy.Session.Store do
  alias Proxy.Session
  alias Chat.State

  @cache :user_cache

  def spec do
    {ConCache,
     [
       name: @cache,
       ttl_check_interval: check_interval(),
       global_ttl: ttl()
     ]}
  end

  def fetch_or_store(user_id, state) do
    new_session = fn -> {:ok, Session.new(user_id, state.())} end

    ConCache.fetch_or_store(@cache, user_id, new_session)
  end

  def add(user_id, %State{} = s) do
    ConCache.update(@cache, user_id, fn
      nil -> {:ok, Session.new(user_id, s)}
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
