defmodule Api.ChatView do
  use Api, :view

  alias Api.Chat.Presenter

  def render("answer.json", %{state: state, fresh: fresh}) do
    context = {Chat.scenarios(), Chat.databases()}

    Presenter.present(state, context)
    |> in_envelope(fresh_error(fresh))
  end

  defp in_envelope(data, error) do
    %{
      data: data,
      error: error
    }
  end

  defp fresh_error(true), do: %{fresh: true}
  defp fresh_error(false), do: nil
end
