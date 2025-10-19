defmodule InventoryWatcher.ProductService do
  alias Absinthe.Subscription
  alias InventoryWatcher.Repo
  alias InventoryWatcher.Product
  alias InventoryWatcherWeb.Endpoint

  @max_stock 150
  @low_stock_threshold 12

  def update_stock(product_id, new_stock_count) do
    case Repo.get(Product, product_id) do
      nil ->
        {:error, :not_found}

      product ->
        changeset = Product.changeset(product, %{stock_count: new_stock_count})

        case Repo.update(changeset) do
          {:ok, updated_product} ->
            # Broadcast the update to all subscribers
            Subscription.publish(Endpoint, updated_product,
              stock_updated: "products:stock_updates"
            )

            {:ok, updated_product}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def simulate_stock_update do
    case Repo.all(Product) do
      [] ->
        {:error, :no_products}

      products ->
        product = Enum.random(products)
        new_stock = next_stock_level(product.stock_count)

        update_stock(product.id, new_stock)
    end
  end

  defp next_stock_level(0), do: Enum.random(10..30)

  defp next_stock_level(current) when current <= @low_stock_threshold do
    case :rand.uniform() do
      roll when roll < 0.5 ->
        apply_sale(current, 1..5)

      roll when roll < 0.9 ->
        apply_restock(current, 5..15)

      _ ->
        apply_restock(current, 15..30)
    end
  end

  defp next_stock_level(current) when current >= @max_stock do
    apply_sale(current, 5..25)
  end

  defp next_stock_level(current) do
    case :rand.uniform() do
      roll when roll < 0.65 ->
        apply_sale(current, 1..12)

      roll when roll < 0.9 ->
        apply_restock(current, 1..8)

      _ ->
        apply_restock(current, 8..20)
    end
  end

  defp apply_sale(current, range) do
    reduction = Enum.random(range)
    max(current - reduction, 0)
  end

  defp apply_restock(current, range) do
    addition = Enum.random(range)
    min(current + addition, @max_stock)
  end
end
