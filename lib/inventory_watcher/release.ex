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

    seed_script = priv_repo_path("seeds.exs")

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          if File.exists?(seed_script) do
            IO.puts("Running seed script for #{inspect(repo)}\n")
            Code.eval_file(seed_script)
          else
            IO.puts("Seed script not found at #{seed_script}, skipping.\n")
          end
        end)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  defp priv_repo_path(filename) do
    Path.join([:code.priv_dir(@app), "repo", filename])
  end
end
