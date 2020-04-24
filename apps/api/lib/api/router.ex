defmodule Api.Router do
  use Api, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", Api do
    pipe_through(:api)

    resources "/chat", ChatController, singleton: true do
      post("/answer", ChatController, :answer, as: :answer)
    end
  end
end
