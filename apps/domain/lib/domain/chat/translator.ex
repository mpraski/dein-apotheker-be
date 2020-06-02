defmodule Chat.Translator do
  @languages ~w[en de]
  @default_language "en"
  @defaults %{scenario: nil, keys: [], translations: %{}, language: @default_language}

  alias Chat.Util

  def languages, do: @languages

  def default_language, do: @default_language

  def translate(item, opts \\ []) do
    opts =
      with opts <- opts |> Enum.into(@defaults),
           scenario <- opts |> Map.get(:scenario),
           language <- opts |> Map.get(:language),
           translations <- Chat.translation(scenario, language) do
        opts
        |> Map.put(:translations, translations)
        |> Map.update!(:keys, &Util.index/1)
      end

    do_translate(item, opts)
  end

  defp do_translate(item, opts) when is_struct(item) do
    item |> Map.from_struct() |> do_translate(opts)
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
         translations: translations
       })
       when is_binary(value) do
    {key, fetch(value, translations)}
  end

  defp do_translate({key, value}, %{
         translations: translations
       })
       when is_list(value) do
    {key, value |> Enum.map(&fetch(&1, translations))}
  end

  defp do_translate(item, _), do: item

  defp fetch(item, translations) do
    %{^item => value} = translations
    value
  end

  defp has_key([], _), do: true
  defp has_key(l, i), do: l |> Map.has_key?(i)
end
