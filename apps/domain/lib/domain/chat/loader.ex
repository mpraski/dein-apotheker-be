defmodule Chat.Loader do
  alias Chat.{Decoder, Validator, Scenario, Question}

  @langauges ~w[en de pl]
  @scenario_file "questions.yaml"

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

    scenario = scenario_path |> YamlElixir.read_from_file!()

    start = scenario |> Decoder.decode_start()
    questions = scenario |> Decoder.decode_questions()

    translations =
      language_paths
      |> Enum.filter(&File.exists?/1)
      |> Enum.map(&YamlElixir.read_from_file!/1)
      |> Enum.map(&Decoder.decode_translations/1)

    # wroong
    translations =
      @langauges
      |> Enum.map(&String.to_atom/1)
      |> Enum.zip(translations)
      |> Map.new()

    with {:error, error} <- Validator.validate_questions(questions) do
      raise error
    end

    for {_, t} <- translations do
      with {:error, error} <- Validator.validate_translations(questions, t) do
        raise error
      end
    end

    questions = questions |> map_questions()

    %Scenario{
      id: id,
      start: start,
      questions: questions,
      translations: translations
    }
  end

  defp map_questions(questions) do
    questions
    |> Enum.map(&extract_id/1)
    |> Enum.zip(questions)
    |> Map.new()
  end

  defp extract_id(%Question.Single{id: id}), do: id
  defp extract_id(%Question.Multiple{id: id}), do: id
  defp extract_id(%Question.Prompt{id: id}), do: id
end
