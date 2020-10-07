defmodule Proxy.ChatView do
  use Proxy, :view

  alias Proxy.Views.Chat, as: View

  def render("answer.json", %{state: state, fresh: fresh}) do
    context = {Chat.scenarios(), Chat.databases()}

    View.present(state, context)
    |> in_envelope(fresh_error(fresh))
  end

  defp fresh_error(true), do: %{fresh: true}
  defp fresh_error(false), do: nil
end
