defmodule Api.Router do
  use Api, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/chat", Api do
    pipe_through(:api)

    post("/answer", ChatController, :answer, as: :answer)
    post("/token", TokenController, :token, as: :token)
  end
end
