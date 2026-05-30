defmodule TypingVim.Release do
  @moduledoc """
  Release tasks for running migrations and seeding inside a built release
  (where Mix is unavailable).

  Usage in production / Fly.io:

      /app/bin/typing_vim eval "TypingVim.Release.migrate"
      /app/bin/typing_vim eval "TypingVim.Release.seed"
  """
  @app :typing_vim

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TypingVim.Repo, fn _repo ->
        seeds_path = Path.join(:code.priv_dir(@app), "repo/seeds.exs")
        Code.eval_file(seeds_path)
      end)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
