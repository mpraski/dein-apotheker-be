defmodule Api.ChatView do
  use Api, :view

  alias Chat.Util

  def render("index.json", %{scenario: scenario}) do
    scenario |> Util.to_map()
  end

  def render("create.json", %{context: {scenarios, question, data}}) do
    %{
      scenarios: scenarios,
      question: question,
      data: data
    }
  end
end
