defmodule Chat.Translator do
  alias Chat.{Decoder, Validator, Scenario, Util}

  @defaults %{scenario: nil, keys: [], language: :en}

  def translate(item, opts \\ []) do
    opts = Enum.into(opts, @defaults)
    do_translate(item, opts)
  end

  defp do_translate(item, %{keys: keys} = opts) when is_map(item) do
    item
    |> Enum.map(fn {k, v} ->
      if in_list(keys, k) do
        do_translate({k, v}, opts)
      else
        {k, do_translate(v, opts)}
      end
    end)
    |> Map.new()
  end

  defp do_translate(item, %{keys: keys} = opts) when is_list(item) do
    item |> Enum.map(&do_translate(&1, opts))
  end

  defp do_translate({key, value}, %{
        scenario: scenario,
        language: language
      })
      when is_binary(value) do
    {key, fetch(value, scenario, language)}
  end

  defp do_translate({key, value}, %{
        scenario: scenario,
        language: language
      })
      when is_list(value) do
    {key, value |> Enum.map(&fetch(&1, scenario, language))}
  end

  defp do_translate(item, _), do: item

  defp fetch(item, scenario, language) do
    %Scenario{translations: translations} = Chat.scenario(scenario)
    %{^item => value} = translations |> Map.get(language)
    value
  end

  defp in_list([], _), do: true
  defp in_list(l, i), do: l |> Enum.member?(i)
end