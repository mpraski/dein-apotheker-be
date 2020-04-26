defmodule Api.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use Api, :controller

  def call(conn, {:error, code, error}) do
    conn
    |> put_status(code)
    |> put_view(Api.ErrorView)
    |> render("api.json", error: error)
  end
end
