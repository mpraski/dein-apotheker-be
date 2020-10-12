defmodule Proxy.ChatView do
  use Proxy, :view

  alias Proxy.Views.Chat, as: View

  def render("answer.json", %{state: state}) do
    state |> View.present(Chat.data()) |> in_envelope()
  end
end
