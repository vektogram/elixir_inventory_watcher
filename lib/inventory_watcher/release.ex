defmodule InventoryWatcher.Release do
  @moduledoc false

  @app :inventory_watcher

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    load_app()

    seed_script = Path.join([:code.priv_dir(@app), "repo", "seeds.exs"])

    for _repo <- repos() do
      if File.exists?(seed_script) do
        Code.eval_file(seed_script)
      end
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
