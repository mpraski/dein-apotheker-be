defmodule Chat do
  alias Chat.{Loader, Scenario}

  @scenarios_path Path.join(File.cwd!(), "../../scenarios")
  @scenarios Loader.load_scenarios(@scenarios_path)

  def scenario(scenario), do: @scenarios |> Map.get(scenario)

  def question(scenario, question) do
    case scenario(scenario) do
      %Scenario{questions: qs} -> qs |> Map.get(question)
      _ -> nil
    end
  end
end
