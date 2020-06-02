defmodule Api.ChatView do
  use Api, :view

  alias Api.ChatHelpers

  @temporary_data ~w[comments comments_scenario]a

  def render("answer.json", %{context: context}) do
    %{
      id: ChatHelpers.id(context),
      input: ChatHelpers.input(context),
      messages: ChatHelpers.messages(context)
    }
    |> in_context(context)
    |> in_envelope()
  end

  def render(
        "languages.json",
        %{
          languages: languages,
          default: default
        }
      ) do
    %{
      languages: languages,
      default: default,
      lel: "lol"
    }
    |> in_envelope()
  end

  defp in_context(item, {scenarios, question, data}) do
    data = @temporary_data |> Enum.reduce(data, &Map.delete(&2, &1))

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
