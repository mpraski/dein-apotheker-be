defmodule Proxy.Session.ProtectCSRF.Test do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest Proxy.Session.ProtectCSRF

  alias Proxy.Session.ProtectCSRF

  test "missing token" do
    conn =
      conn(:post, "/route")
      |> init_test_session(%{})
      |> ProtectCSRF.call([])

    assert {401, _, ""} = sent_resp(conn)
  end

  test "present token, missing header" do
    token = UUID.uuid4()

    conn =
      conn(:post, "/route")
      |> init_test_session(%{csrf_token: token})
      |> ProtectCSRF.call([])

    assert {401, _, ""} = sent_resp(conn)
  end

  test "present token, present header" do
    token = UUID.uuid4()

    conn =
      conn(:post, "/route")
      |> init_test_session(%{csrf_token: token})
      |> put_req_header("x-csrf-token", token)
      |> ProtectCSRF.call([])

    assert !conn.halted
  end
end
