defmodule InventoryWatcherWeb.Schema do
  use Absinthe.Schema
  import_types(InventoryWatcherWeb.Schema.ProductTypes)

  def context(ctx) do
    Map.put(ctx, :pubsub, InventoryWatcherWeb.Endpoint)
  end

  query do
    @desc "Get all products"
    field :products, list_of(:product) do
      resolve(&InventoryWatcherWeb.Resolvers.ProductResolver.list_products/3)
    end
  end

  subscription do
    @desc "Subscribe to stock updates"
    field :stock_updated, :product do
      config(fn _args, _info ->
        {:ok, topic: "products:stock_updates"}
      end)

      resolve(fn product, _args, _info ->
        {:ok, product}
      end)
    end
  end
end
