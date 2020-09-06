defmodule Chat.Data.Database do
  @enforce_keys ~w[id headers rows]a

  defstruct id: nil,
            headers: [],
            rows: [],
            indexed: %{}

  def new(id, [headers | rows]) do
    with headers <- headers |> Enum.map(&String.to_atom/1) do
      %__MODULE__{
        id: id,
        headers: headers,
        rows: rows,
        indexed: make_indexed(headers, rows)
      }
    end
  end

  defp make_indexed(headers, rows) do
    rows
    |> Enum.reduce(%{}, fn r, m ->
      headers
      |> Enum.zip(r)
      |> Enum.reduce(m, fn {h, v}, m ->
        Map.update(m, h, [v], &[v | &1])
      end)
    end)
    |> Enum.map(fn {k, v} -> {k, Enum.reverse(v)} end)
    |> Enum.into(Map.new)
  end
end
