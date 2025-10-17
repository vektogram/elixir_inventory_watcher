# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     InventoryWatcher.Repo.insert!(%InventoryWatcher.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias InventoryWatcher.Repo
alias InventoryWatcher.Product

# Create sample products
products = [
  %{name: "Wireless Bluetooth Headphones", sku: "WBH-001", stock_count: 25},
  %{name: "Mechanical Gaming Keyboard", sku: "MGK-002", stock_count: 12},
  %{name: "4K Ultra HD Monitor", sku: "4KUHD-003", stock_count: 8},
  %{name: "Wireless Charging Pad", sku: "WCP-004", stock_count: 45},
  %{name: "USB-C Hub Adapter", sku: "USBC-005", stock_count: 30},
  %{name: "Ergonomic Office Chair", sku: "EOC-006", stock_count: 5},
  %{name: "Smart Home Security Camera", sku: "SHSC-007", stock_count: 18},
  %{name: "Portable SSD Drive", sku: "PSSDD-008", stock_count: 22}
]

Enum.each(products, fn product_attrs ->
  %Product{}
  |> Product.changeset(product_attrs)
  |> Repo.insert!()
end)

IO.puts("Seeded #{length(products)} products")
