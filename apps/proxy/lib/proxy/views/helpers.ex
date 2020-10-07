defmodule Proxy.View.Helpers do
  def in_envelope(data, error \\ nil) do
    %{
      data: data,
      error: error
    }
  end
end
