defmodule Chat.Loader do
  @moduledoc """
  Loader loads the chatbot data
  """

  alias Chat.Scenario.Loader, as: ScenarioLoader
  alias Chat.Scenario.Parser, as: ScenarioParser
  alias Chat.Database.Loader, as: DatabaseLoader

  def load(scenarios, databases) do
    {:ok, _} = Application.ensure_all_started(:xlsxir)

    data = {
      scenarios |> ScenarioLoader.load() |> ScenarioParser.parse(),
      databases |> DatabaseLoader.load()
    }

    Application.stop(:xlsxir)

    data
  end
end
