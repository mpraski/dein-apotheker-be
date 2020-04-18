defmodule Chat do
  alias Chat.{Loader, Scenario}

  @scenarios_path Path.join(File.cwd!(), "../../scenarios")
  @scenarios Loader.load_scenarios(@scenarios_path)

  def scenario(scenario), do: @scenarios |> Map.get(scenario)

  def question(scenario, question) do
    case scenario(scenario) do
      %Scenario{questions: questions} -> questions |> Map.get(question)
      _ -> nil
    end
  end

  def translation(scenario, language, key) do
    case scenario(scenario) do
      %Scenario{translations: translations} ->
        translations |> Kernel.get_in([language, key])

      _ ->
        nil
    end
  end
end
