defmodule Proxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Proxy.Endpoint
  alias Proxy.Session.Store

  def start(_type, _args) do
    {:ok, _} = Application.ensure_all_started(:chat)

    children = [
      Store.spec(),
      Endpoint
    ]

    opts = [strategy: :one_for_one, name: Proxy.Supervisor]

    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Proxy.Endpoint.config_change(changed, removed)
    :ok
  end
end
