defmodule Chat.Database do
  @enforce_keys ~w[id headers rows]a

  defstruct id: nil,
            headers: [],
            rows: [],
            indexed: %{}

  def new(id, [headers | rows]) do
    with headers <- headers |> Enum.map(&to_atom/1) do
      %__MODULE__{
        id: id,
        headers: headers,
        rows: rows
      }
    end
  end

  def indexed(id, data) do
    db = %__MODULE__{headers: headers, rows: rows} = new(id, data)
    %__MODULE__{db | indexed: make_indexed(headers, rows)}
  end

  def index(
        %__MODULE__{
          headers: headers,
          rows: rows
        } = db
      ) do
    %__MODULE__{db | indexed: make_indexed(headers, rows)}
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
    |> Enum.into(Map.new())
  end

  defp to_atom(a) when is_atom(a), do: a

  defp to_atom(a) when is_binary(a), do: String.to_atom(a)
end
