defmodule Chat.Loader do
  alias Chat.{Decoder, Validator, Scenario, Translator, Util}

  @yaml YamlElixir
  @scenario_file "questions.yaml"
  @products_file "products.yaml"

  def load_scenarios(path) do
    File.ls!(path)
    |> Enum.map(&Path.join(path, &1))
    |> Enum.filter(&File.dir?/1)
    |> Enum.map(&load_scenario/1)
    |> by(:id)
  end

  defp load_scenario(path) do
    id = Path.basename(path)

    scenario =
      path
      |> Path.join(@scenario_file)
      |> @yaml.read_from_file!()

    products =
      with path <- Path.join(path, @products_file),
           true <- File.exists?(path) do
        path |> @yaml.read_from_file!()
      end

    start = scenario |> Decoder.decode_start()
    questions = scenario |> Decoder.decode_questions()
    products = products |> Decoder.decode_products()

    translations =
      Translator.languages()
      |> Enum.zip(Translator.languages() |> Enum.map(&Path.join(path, "#{&1}.yaml")))
      |> Enum.filter(fn {_, p} -> File.exists?(p) end)
      |> Enum.map(fn {l, p} -> {l, @yaml.read_from_file!(p)} end)
      |> Map.new()
      |> Decoder.decode_translations()

    scenario = %Scenario{
      id: id,
      start: start,
      questions: questions,
      products: products,
      translations: translations
    }

    with {:error, error} <- Validator.validate(scenario) do
      raise "Error validating scenario #{id}: #{error}"
    end

    %Scenario{scenario | questions: questions |> by(:id), products: products |> by(:id)}
  end

  defp by(items, key) do
    items
    |> Enum.map(&Util.pluck(&1, key))
    |> Enum.zip(items)
    |> Map.new()
  end
end
