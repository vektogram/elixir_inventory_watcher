defmodule InventoryWatcherWeb.Schema.ProductTypes do
  use Absinthe.Schema.Notation

  object :product do
    field :id, :id
    field :name, :string
    field :sku, :string
    field :stock_count, :integer
    field :inserted_at, :string
    field :updated_at, :string
  end
end
