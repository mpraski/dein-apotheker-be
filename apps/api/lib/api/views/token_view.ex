defmodule Api.TokenView do
  use Api, :view

  def render("token.json", %{token: token}), do: token |> in_envelope()
end
