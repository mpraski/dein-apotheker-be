defmodule Proxy.Router do
  use Proxy, :router

  use Plug.ErrorHandler

  alias Proxy.ErrorView
  alias Phoenix.Controller

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth do
    plug(Proxy.Session.Verify)
  end

  pipeline :ensure_auth do
    plug(Proxy.Session.Enforce)
  end

  scope "/chat", Proxy do
    pipe_through([:api, :auth, :ensure_auth])

    post("/answer", ChatController, :answer)
  end

  scope "/session", Proxy do
    pipe_through([:api, :auth])

    get("/", SessionController, :has)
    post("/", SessionController, :new)
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    conn
    |> put_status(500)
    |> Controller.put_view(ErrorView)
    |> Controller.render("server.json")
  end
end
