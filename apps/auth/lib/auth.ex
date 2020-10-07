defmodule Auth do
  @moduledoc """
  Documentation for `Auth`.
  """

  alias Auth.Guardian

  def authenticate(token) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} -> {:ok, claims["sub"]}
      {:error, reason} -> {:error, reason}
    end
  end
end
