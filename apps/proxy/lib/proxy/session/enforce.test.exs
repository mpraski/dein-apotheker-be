defmodule Proxy.Session.Enforce.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Proxy.Session.Enforce

  alias Proxy.Session
  alias Proxy.Session.Store
  alias Proxy.Session.Enforce
  alias Account.User

  setup do
    start_supervised(Store.spec(), [])
    :ok
  end

  test "missing user" do
    conn =
      conn(:post, "/route")
      |> Enforce.call([])

    assert {401, _, ""} = sent_resp(conn)
  end

  test "present user" do
    user = User.new("uid")

    conn =
      conn(:post, "/route")
      |> assign(:user, user)
      |> Enforce.call([])

    session = Session.new("uid")

    assert session == conn.assigns.session
  end
end
