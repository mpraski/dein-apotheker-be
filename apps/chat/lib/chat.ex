defmodule Chat do
  @moduledoc """
  Chat consolidates commonnly used data and function
  """

  @scenario_path Application.get_env(:chat, :scenario_path)
  @database_path Application.get_env(:chat, :database_path)

  @data Chat.Loader.load(@scenario_path, @database_path)

  alias Chat.Scenario
  alias Chat.Scenario.Process
  alias Chat.Scenario.Question

  def data() do
    @data
  end

  def scenarios() do
    {a, _} = @data
    a
  end

  def databases() do
    {_, b} = @data
    b
  end

  def question_id(scenarios, process, scenario) do
    {:ok, scenario} = scenarios |> Map.fetch(scenario)
    {:ok, process} = scenario |> Scenario.process(process)
    {:ok, %Question{id: question_id}} = Process.entry(process)

    question_id
  end
end
