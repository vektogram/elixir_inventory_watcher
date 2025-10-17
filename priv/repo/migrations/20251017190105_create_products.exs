defmodule InventoryWatcher.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :sku, :string, null: false
      add :stock_count, :integer, null: false, default: 0

      timestamps()
    end

    create unique_index(:products, [:sku])
  end
end
