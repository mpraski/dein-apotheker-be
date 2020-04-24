defmodule Api.ChatView do
  use Api, :view

  alias Api.ChatHelpers

  @temporary_data ~w[comments]a

  def render("answer.json", %{context: context}) do
    %{
      id: ChatHelpers.id(context),
      input: ChatHelpers.input(context),
      messages: ChatHelpers.messages(context)
    }
    |> in_context(context)
    |> in_envelope()
  end

  defp in_envelope(item) do
    %{
      error: nil,
      content: item
    }
  end

  defp in_context(item, {scenarios, question, data}) do
    data =
      @temporary_data
      |> Enum.reduce(data, fn k, m -> Map.delete(m, k) end)

    %{
      context: %{
        scenarios: scenarios,
        question: question,
        data: data
      },
      data: item
    }
  end
end
