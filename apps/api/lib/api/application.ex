defmodule Api.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Api.Endpoint
  alias Api.HealthCheck

  def start(_type, _args) do
    # make sure domain stared because of runtime dependencies
    {:ok, _} = Application.ensure_all_started(:domain)

    # List all child processes to be supervised
    children = [
      {HealthCheck,
       {
         [HealthCheck.repo?(Domain.Repo)],
         [HealthCheck.alive?(&Chat.Recorder.pid/0)]
       }},
      Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Api.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Api.Endpoint.config_change(changed, removed)
    :ok
  end
end
