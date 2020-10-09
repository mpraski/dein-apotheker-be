defmodule Proxy.Session.Store.Test do
  use ExUnit.Case, async: true
  doctest Proxy.Session.Store

  alias Proxy.Session
  alias Proxy.Session.Store

  setup do
    start_supervised(Store.spec(), [])
    :ok
  end

  test "new session" do
    assert Store.new_or_fetch("uid") == Session.new("uid")
  end

  test "existing session" do
    sess = Session.new("uid")

    Store.put(sess)

    assert Store.new_or_fetch("uid") == sess
  end
end
