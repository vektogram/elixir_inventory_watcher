defmodule InventoryWatcher.Repo do
  use Ecto.Repo,
    otp_app: :inventory_watcher,
    adapter: Ecto.Adapters.Postgres
end
