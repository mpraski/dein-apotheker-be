defmodule Proxy.Session.Store do
  alias Proxy.Session

  @cache :user_cache
  @cache_ttl Application.get_env(:proxy, :cache_ttl)
  @cache_check Application.get_env(:proxy, :cache_check)

  def spec do
    {ConCache,
     [
       name: @cache,
       ttl_check_interval: @cache_check,
       global_ttl: @cache_ttl
     ]}
  end

  def new_or_fetch(user_id) do
    new_session = fn -> {:ok, Session.new(user_id)} end

    {:ok, session} = ConCache.fetch_or_store(@cache, user_id, new_session)

    session
  end

  def put(%Session{user_id: user_id} = session) do
    :ok = ConCache.put(@cache, user_id, session)

    session
  end

  def ttl do
    @cache_ttl
  end
end
