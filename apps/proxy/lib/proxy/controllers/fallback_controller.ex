defmodule Proxy.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use Proxy, :controller

  def call(conn, {:error, code, error}) do
    conn
    |> put_status(code)
    |> put_view(Proxy.ErrorView)
    |> render("Proxy.json", error: error)
  end
end
