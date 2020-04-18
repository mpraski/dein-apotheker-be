defmodule Chat.Loader do
  alias Chat.{Decoder, Scenario}

  @langauges ~w[en de pl]
  @scenario_file "scenario.yaml"

  def load_scenarios(path) do
    File.ls!(path)
    |> Enum.map(&Path.join(path, &1))
    |> Enum.filter(&File.dir?/1)
    |> Enum.map(&load_scenario/1)
    |> Enum.map(fn %Scenario{id: id} = s -> {id, s} end)
    |> Map.new()
  end

  defp load_scenario(path) do
    id = String.to_atom(Path.basename(path))
    scenario_path = Path.join(path, @scenario_file)
    language_paths = @langauges |> Enum.map(&Path.join(path, "#{&1}.yaml"))

    questions =
      scenario_path
      |> YamlElixir.read_from_file!()
      |> Decoder.decode_questions()

    with {:error, error} <- Decoder.validate_questions(questions) do
      raise error
    end

    questions = questions |> Decoder.map_questions()

    translations =
      language_paths
      |> Enum.filter(&File.exists?/1)
      |> Enum.map(&YamlElixir.read_from_file!/1)
      |> Enum.map(&Decoder.decode_translations/1)

    translations =
      @langauges
      |> Enum.map(&String.to_atom/1)
      |> Enum.zip(translations)
      |> Map.new()

    %Scenario{
      id: id,
      questions: questions,
      translations: translations
    }
  end
end
