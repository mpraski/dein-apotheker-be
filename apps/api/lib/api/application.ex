defmodule Api.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Api.Endpoint
  alias Api.User.Sessions

  def start(_type, _args) do
    {:ok, _} = Application.ensure_all_started(:domain)

    children = [
      Sessions.spec(),
      Endpoint
    ]

    opts = [strategy: :one_for_one, name: Api.Supervisor]

    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Api.Endpoint.config_change(changed, removed)
    :ok
  end
end
