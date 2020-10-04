defmodule Api.User.Token do
  alias Phoenix.Token
  alias Api.User.Journeys

  @salt "user_auth_" <> "hIgeRWHc"

  def sign(user_id) do
    Token.sign(Api.Endpoint, @salt, user_id)
  end

  def verify(nil), do: nil

  def verify(token) do
    Token.verify(Api.Endpoint, @salt, token, max_age: Journeys.ttl())
  end
end
