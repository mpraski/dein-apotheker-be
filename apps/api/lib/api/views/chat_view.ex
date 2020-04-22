defmodule Api.ChatView do
  use Api, :view

  alias Api.ChatHelpers

  def render("create.json", %{context: context}) do
    with response <- %{
           id: ChatHelpers.id(context),
           input: ChatHelpers.input(context),
           messages: ChatHelpers.messages(context)
         } do
      context |> with_context(response)
    end
  end

  defp with_context({scenarios, question, data}, content) do
    {_, data} = data |> Map.pop(:comments)

    %{
      context: %{
        scenarios: scenarios,
        question: question,
        data: data
      },
      data: content
    }
  end
end
