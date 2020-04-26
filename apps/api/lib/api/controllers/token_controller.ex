defmodule Api.TokenController do
  use Api, :controller

  def token(conn, _params) do
    with token <- UUID.uuid4() do
      conn |> render("token.json", token: token)
    end
  end
end
