defmodule Proxy.View.Helpers do
  @moduledoc """
  Helpers for rendering views
  """

  def in_envelope(data, error \\ nil) do
    %{
      data: data,
      error: error
    }
  end
end
