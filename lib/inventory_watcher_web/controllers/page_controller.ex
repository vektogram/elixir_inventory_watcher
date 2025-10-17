defmodule InventoryWatcherWeb.PageController do
  use InventoryWatcherWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def simulate_stock_update(conn, _params) do
    case InventoryWatcher.ProductService.simulate_stock_update() do
      {:ok, product} ->
        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          message: "Stock updated successfully",
          product: %{
            id: product.id,
            name: product.name,
            sku: product.sku,
            stock_count: product.stock_count
          }
        })

      {:error, :no_products} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, message: "No products available to update"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, message: "Failed to update stock", errors: changeset.errors})
    end
  end
end
