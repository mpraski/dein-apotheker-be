defmodule Chat.Loader do
  alias Chat.{Decoder, Validator, Scenario, Translator, Util}

  @yaml YamlElixir
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
      Translator.languages()
      |> Enum.zip(Translator.languages() |> Enum.map(&Path.join(path, "#{&1}.yaml")))
      |> Enum.filter(fn {_, p} -> File.exists?(p) end)
      |> Enum.map(fn {l, p} -> {l, @yaml.read_from_file!(p)} end)
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

    %Scenario{scenario | questions: by_id(questions)}
  end

  defp by_id(items) do
    items
    |> Enum.map(&Util.pluck(&1, :id))
    |> Enum.zip(items)
    |> Map.new()
  end
end
