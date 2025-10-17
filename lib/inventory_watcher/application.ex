defmodule InventoryWatcher.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      InventoryWatcherWeb.Telemetry,
      InventoryWatcher.Repo,
      {DNSCluster, query: Application.get_env(:inventory_watcher, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: InventoryWatcher.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: InventoryWatcher.Finch},
      # Start a worker by calling: InventoryWatcher.Worker.start_link(arg)
      # {InventoryWatcher.Worker, arg},
      # Start to serve requests, typically the last entry
      InventoryWatcherWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InventoryWatcher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    InventoryWatcherWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
