defmodule Auth do
  @moduledoc """
  Documentation for `Auth`.
  """

  alias Auth.Guardian

  @grace Application.get_env(:auth, :grace, 600)

  def authenticate(nil), do: {:error, :missing}

  def authenticate(token) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        sub = claims["sub"]

        now = DateTime.utc_now()

        grace = now |> DateTime.add(@grace)

        exp = claims["exp"] |> DateTime.from_unix!(:second)

        case DateTime.compare(now, exp) do
          r when r in [:gt, :eq] ->
            {:error, :expired}

          _ ->
            case DateTime.compare(grace, exp) do
              r when r in [:gt, :eq] -> {:expiring, sub}
              _ -> {:ok, sub}
            end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
