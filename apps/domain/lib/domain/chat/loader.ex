defmodule Chat.Loader do
  alias Chat.{Decoder, Validator, Scenario, Util}

  @yaml YamlElixir
  @langauges ~w[en de pl]
  @scenario_file "questions.yaml"

  def load_scenarios(path) do
    File.ls!(path)
    |> Enum.map(&Path.join(path, &1))
    |> Enum.filter(&File.dir?/1)
    |> Enum.map(&load_scenario/1)
    |> by_id()
  end

  defp load_scenario(path) do
    id = Path.basename(path)

    scenario =
      path
      |> Path.join(@scenario_file)
      |> @yaml.read_from_file!()

    start = scenario |> Decoder.decode_start()
    questions = scenario |> Decoder.decode_questions()

    translations =
      @langauges
      |> Enum.map(&String.to_atom/1)
      |> Enum.zip(@langauges |> Enum.map(&Path.join(path, "#{&1}.yaml")))
      |> Enum.filter(fn {_, p} -> File.exists?(p) end)
      |> Enum.map(fn {l, p} -> {l, @yaml.read_from_file!(p)} end)
      |> Enum.map(fn {l, p} -> {l, Decoder.decode_translations(p)} end)
      |> Map.new()

    scenario = %Scenario{
      id: id,
      start: start,
      questions: questions,
      translations: translations
    }

    with {:error, error} <- Validator.validate(scenario) do
      raise error
    end

    scenario
  end

  defp by_id(items) do
    items
    |> Enum.map(&Util.pluck(&1, :id))
    |> Enum.zip(items)
    |> Map.new()
  end
end
