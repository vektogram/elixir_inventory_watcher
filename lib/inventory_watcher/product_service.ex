defmodule InventoryWatcher.ProductService do
  alias Absinthe.Subscription
  alias InventoryWatcher.Repo
  alias InventoryWatcher.Product
  alias InventoryWatcherWeb.Endpoint

  def update_stock(product_id, new_stock_count) do
    case Repo.get(Product, product_id) do
      nil ->
        {:error, :not_found}

      product ->
        changeset = Product.changeset(product, %{stock_count: new_stock_count})

        case Repo.update(changeset) do
          {:ok, updated_product} ->
            # Broadcast the update to all subscribers
            Subscription.publish(Endpoint, updated_product, stock_updated: "products:stock_updates")
            {:ok, updated_product}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def simulate_stock_update do
    # Get a random product
    case Repo.all(Product) do
      [] ->
        {:error, :no_products}

      products ->
        product = Enum.random(products)
        # Random stock change between -5 and +10
        change = Enum.random(-5..10)
        new_stock = max(0, product.stock_count + change)

        update_stock(product.id, new_stock)
    end
  end
end
