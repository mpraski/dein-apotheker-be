defmodule Chat do
  @moduledoc """
  Chat consolidates commonnly used data and function
  """

  use Agent

  @scenario_path Application.get_env(:chat, :scenario_path)
  @database_path Application.get_env(:chat, :database_path)

  alias Chat.Scenario.Loader, as: ScenarioLoader
  alias Chat.Scenario.Parser, as: ScenarioParser
  alias Chat.Database.Loader, as: DatabaseLoader

  def start_link(_opts) do
    Agent.start_link(&state/0, name: __MODULE__)
  end

  def scenarios() do
    Agent.get(__MODULE__, &elem(&1, 0))
  end

  def databases() do
    Agent.get(__MODULE__, &elem(&1, 1))
  end

  defp state do
    {
      @scenario_path |> ScenarioLoader.load() |> ScenarioParser.parse(),
      @database_path |> DatabaseLoader.load()
    }
  end
end
