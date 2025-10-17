defmodule InventoryWatcher.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :sku, :string
    field :stock_count, :integer

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :sku, :stock_count])
    |> validate_required([:name, :sku, :stock_count])
    |> validate_number(:stock_count, greater_than_or_equal_to: 0)
    |> unique_constraint(:sku)
  end
end
