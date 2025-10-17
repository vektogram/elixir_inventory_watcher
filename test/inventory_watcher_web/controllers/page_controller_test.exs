defmodule InventoryWatcherWeb.PageControllerTest do
  use InventoryWatcherWeb.ConnCase, async: false
  alias InventoryWatcher.Repo
  alias InventoryWatcher.Product

  setup do
    # Seed some products for testing
    products = [
      %{name: "Wireless Bluetooth Headphones", sku: "WBH-001", stock_count: 25},
      %{name: "Mechanical Gaming Keyboard", sku: "MGK-002", stock_count: 12}
    ]

    Enum.each(products, fn product_attrs ->
      %Product{}
      |> Product.changeset(product_attrs)
      |> Repo.insert!()
    end)

    :ok
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end

  test "POST /api/simulate-stock-update", %{conn: conn} do
    conn = post(conn, "/api/simulate-stock-update")
    assert json_response(conn, 200)["success"] == true
    assert json_response(conn, 200)["message"] == "Stock updated successfully"
    assert Map.has_key?(json_response(conn, 200)["product"], "id")
    assert Map.has_key?(json_response(conn, 200)["product"], "name")
    assert Map.has_key?(json_response(conn, 200)["product"], "sku")
    assert Map.has_key?(json_response(conn, 200)["product"], "stock_count")
  end
end
