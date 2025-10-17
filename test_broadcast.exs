#!/usr/bin/env elixir

# Simple test to verify subscription broadcasting works
# Run with: elixir test_broadcast.exs

# Start the application to test broadcasting
Application.ensure_all_started(:inventory_watcher)

# Test the broadcasting by calling the service
IO.puts("Testing subscription broadcasting...")

case InventoryWatcher.ProductService.simulate_stock_update() do
  {:ok, product} ->
    IO.puts("✅ Stock update successful!")
    IO.puts("📦 Updated product: #{product.name} (#{product.sku})")
    IO.puts("📊 New stock count: #{product.stock_count}")
    IO.puts("")

    IO.puts(
      "If subscriptions are working, clients connected to the 'products:stock_updates' topic"
    )

    IO.puts("should have received a 'stock_updated' event with the product data.")

  {:error, reason} ->
    IO.puts("❌ Stock update failed: #{inspect(reason)}")
end
