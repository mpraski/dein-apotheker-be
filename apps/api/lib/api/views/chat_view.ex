defmodule Api.ChatView do
  use Api, :view

  def render("answer.json", %{state: state}) do
    in_envelope(state)
  end
end
