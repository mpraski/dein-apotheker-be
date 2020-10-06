defmodule Proxy.Router do
  use Proxy, :router

  use Plug.ErrorHandler

  alias Proxy.ErrorView
  alias Phoenix.Controller

  pipeline :proxy do
    plug(:accepts, ["json"])
    plug(Proxy.Session.Plug)
  end

  scope "/proxy", Proxy do
    pipe_through(:proxy)

    post("/answer", ChatController, :answer)
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    conn
    |> put_status(500)
    |> Controller.put_view(ErrorView)
    |> Controller.render("server.json")
  end
end
