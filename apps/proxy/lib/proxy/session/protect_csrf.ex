defmodule Proxy.Session.ProtectCSRF do
  @moduledoc """
  Verify if the session token is present
  and attempt to load corresponding user id
  """

  import Plug.Conn

  alias Plug.Conn

  @header "x-csrf-token"

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    csrf_token = conn |> get_session(:csrf_token)
    csrf_header = conn |> get_req_header(@header)

    if [csrf_token] == csrf_header do
      conn
    else
      conn
      |> send_resp(:unauthorized, "")
      |> halt()
    end
  end
end
