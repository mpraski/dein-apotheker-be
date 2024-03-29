defmodule Proxy.Router do
  use Proxy, :router

  use Plug.ErrorHandler

  alias Proxy.Session.{Verify, Enforce, ProtectCSRF}

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:fetch_session)
  end

  # Just verify if we have a valid session
  # defined by the JWT token in the cookie
  pipeline :verify_auth do
    plug(Verify)
  end

  # Enfore the CSRF + JWT presence in the cookie
  pipeline :ensure_auth do
    plug(ProtectCSRF)
    plug(Verify)
    plug(Enforce)
  end

  scope "/chat", Proxy do
    pipe_through([:api, :ensure_auth])

    get("/peek", ChatController, :peek)
    post("/answer", ChatController, :answer)
  end

  scope "/session", Proxy do
    pipe_through([:api, :verify_auth])

    get("/", SessionController, :has)
    post("/", SessionController, :new)
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    conn |> render_error(:internal_server_error)
  end

  defp render_error(conn, status) do
    conn
    |> send_resp(status, "")
    |> halt()
  end
end
