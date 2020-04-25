defmodule Chat do
  alias Chat.{Loader, Scenario}

  @scenarios_path Path.join(File.cwd!(), "../../scenarios")
  @scenarios Loader.load_scenarios(@scenarios_path)

  def scenario(scenario), do: @scenarios |> Map.get(scenario)

  def question(nil, _), do: nil

  def question(%Scenario{questions: questions}, q) do
    questions |> Map.get(q)
  end

  def question(scenario, question) do
    question(scenario(scenario), question)
  end
end
