defmodule Proxy.Session.Test do
  use ExUnit.Case, async: true
  doctest Proxy.Session

  alias Proxy.Session
  alias Chat.State

  test "new session" do
    assert Session.new("uid") == %Session{user_id: "uid", states: %{}}
  end

  test "add state" do
    state = %State{id: sid} = State.new(:q, [], []) |> State.generate_id()

    sess = Session.new("uid") |> Session.add(state)

    assert sess == %Session{user_id: "uid", states: %{sid => state}}
  end

  test "fetch state" do
    state = %State{id: sid} = State.new(:q, [], []) |> State.generate_id()

    sess = Session.new("uid") |> Session.add(state)

    assert Session.fetch(sess, sid) == {:ok, state}
  end

  test "fetch noenxistent state" do
    sess = Session.new("uid")

    assert Session.fetch(sess, "lel") == :error
  end
end
