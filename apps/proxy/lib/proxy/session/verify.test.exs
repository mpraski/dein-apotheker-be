defmodule Proxy.Session.Verify.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Proxy.Session.Verify

  alias Proxy.Session.Verify
  alias Account.User

  test "token not present" do
    conn =
      conn(:post, "/route")
      |> init_test_session(%{})
      |> Verify.call([])

    assert conn.assigns.user == nil
  end

  test "token present but invalid" do
    conn =
      conn(:post, "/route")
      |> init_test_session(%{token: "wrong"})
      |> Verify.call([])

    assert conn.assigns.user == nil
  end

  test "token present and valid" do
    {:ok, token, %User{id: id}} = Auth.Issuer.guest()

    conn =
      conn(:post, "/route")
      |> init_test_session(%{token: token})
      |> Verify.call([])

    assert conn.assigns.user == id
  end
end
