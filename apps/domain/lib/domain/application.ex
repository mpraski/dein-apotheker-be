defmodule Domain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Chat.Recorder

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Domain.Worker.start_link(arg)
      # {Domain.Repo, []}
      Recorder
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Domain.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    Recorder.add_exporter(fn _ -> :ok end)

    {:ok, pid}
  end
end
