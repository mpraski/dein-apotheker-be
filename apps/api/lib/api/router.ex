defmodule Api.Router do
  use Api, :router

  use Plug.ErrorHandler

  alias Api.ErrorView
  alias Phoenix.Controller

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/chat", Api do
    pipe_through(:api)

    post("/answer", ChatController, :answer)
    post("/languages", ChatController, :languages)
    post("/token", TokenController, :token)
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    conn
    |> put_status(500)
    |> Controller.put_view(ErrorView)
    |> Controller.render("server.json")
  end
end
