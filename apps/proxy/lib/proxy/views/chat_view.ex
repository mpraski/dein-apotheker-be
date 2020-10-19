defmodule Proxy.ChatView do
  use Proxy, :view

  alias Proxy.Views.Chat, as: View

  def render("answer.json", %{state: state}) do
    state |> View.present() |> in_envelope()
  end
end
