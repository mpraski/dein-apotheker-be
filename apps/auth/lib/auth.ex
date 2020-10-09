defmodule Auth do
  @moduledoc """
  Documentation for `Auth`.
  """

  @grace 600

  alias Auth.Guardian

  def authenticate(nil), do: {:error, :missing}

  def authenticate(token) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        sub = claims["sub"]

        now = DateTime.utc_now() |> DateTime.add(@grace)

        exp =
          claims
          |> Map.get("exp")
          |> DateTime.from_unix!(:second)

        case DateTime.compare(now, exp) do
          :gt -> {:expiring, sub}
          _ -> {:ok, sub}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
