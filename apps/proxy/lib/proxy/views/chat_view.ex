defmodule Proxy.ChatView do
  use Proxy, :view

  alias Proxy.Views.Chat, as: View

  def render("answer.json", %{state: state}) do
    context = {Chat.scenarios(), Chat.databases()}

    state |> View.present(context) |> in_envelope()
  end
end
