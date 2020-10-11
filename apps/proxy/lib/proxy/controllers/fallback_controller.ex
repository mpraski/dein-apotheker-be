defmodule Proxy.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use Proxy, :controller

  def call(conn, {:error, code}) do
    conn
    |> send_resp(code, "")
    |> halt()
  end
end
