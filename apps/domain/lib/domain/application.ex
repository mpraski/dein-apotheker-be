defmodule Domain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Chat.Recorder
  alias Repo.Journey

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Domain.Worker.start_link(arg)
      # {Domain.Repo, []},
      {Recorder,
       [
         &Journey.export/1,
         &Journey.export_log/1
       ]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Domain.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
