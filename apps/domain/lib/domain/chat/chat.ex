defmodule Chat do
  alias Chat.{Loader, Scenario}

  @scenarios_path Path.join(File.cwd!(), Application.get_env(:domain, :scenario_path))
  @scenarios Loader.load_scenarios(@scenarios_path)

  def scenario(scenario), do: @scenarios |> Map.get(scenario)

  def question(nil, _), do: nil

  def question(%Scenario{questions: questions}, q) do
    questions |> Map.get(q)
  end

  def question(scenario, question) do
    question(scenario(scenario), question)
  end

  def product(%Scenario{products: products}, p) do
    products |> Map.get(p)
  end

  def product(scenario, product) do
    product(scenario(scenario), product)
  end
end
