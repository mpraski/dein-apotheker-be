defmodule Chat.Translator do
  alias Chat.Scenario

  @defaults %{scenario: nil, keys: [], language: :en}

  alias Chat.Util

  def translate(item, opts \\ []) do
    opts =
      opts
      |> Enum.into(@defaults)
      |> Map.update!(:keys, &Util.index/1)

    do_translate(item, opts)
  end

  defp do_translate(item, %{keys: keys} = opts) when is_map(item) do
    item
    |> Enum.map(fn {k, v} ->
      if has_key(keys, k) do
        do_translate({k, v}, opts)
      else
        {k, do_translate(v, opts)}
      end
    end)
    |> Map.new()
  end

  defp do_translate(item, opts) when is_list(item) do
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

  defp has_key([], _), do: true
  defp has_key(l, i), do: l |> Map.has_key?(i)
end
