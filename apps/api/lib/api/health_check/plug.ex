defmodule Api.HealthCheck.Plug do
  @moduledoc """
  Plug for routing health check requests
  """

  import Plug.Conn

  alias Api.HealthCheck

  @behaviour Plug

  def init(_params) do
  end

  def call(%{path_info: ["ready"]} = conn, _opts) do
    conn
    |> send_resp(code(HealthCheck.check_readiness()), "")
    |> halt()
  end

  def call(%{path_info: ["live"]} = conn, _opts) do
    conn
    |> send_resp(code(HealthCheck.check_liveness()), "")
    |> halt()
  end

  def call(conn, _opts), do: conn

  defp code(r) do
    case r do
      :ok -> :ok
      :error -> :internal_server_error
    end
  end
end
