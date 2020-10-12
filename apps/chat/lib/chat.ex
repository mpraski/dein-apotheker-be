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

  alias Chat.Scenario
  alias Chat.Scenario.Process
  alias Chat.Scenario.Question

  def start_link(_opts) do
    Agent.start_link(&state/0, name: __MODULE__)
  end

  def data() do
    Agent.get(__MODULE__, &(&1))
  end

  def scenarios() do
    Agent.get(__MODULE__, &elem(&1, 0))
  end

  def databases() do
    Agent.get(__MODULE__, &elem(&1, 1))
  end

  def question_id(scenarios, process, scenario) do
    {:ok, scenario} = scenarios |> Map.fetch(scenario)
    {:ok, process} = scenario |> Scenario.process(process)
    {:ok, %Question{id: question_id}} = Process.entry(process)

    question_id
  end

  defp state do
    {
      @scenario_path |> ScenarioLoader.load() |> ScenarioParser.parse(),
      @database_path |> DatabaseLoader.load()
    }
  end
end
