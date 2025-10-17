defmodule InventoryWatcherWeb.Resolvers.ProductResolver do
  alias InventoryWatcher.Repo
  alias InventoryWatcher.Product

  def list_products(_parent, _args, _resolution) do
    {:ok, Repo.all(Product)}
  end
end
