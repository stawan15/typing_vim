defmodule TypingVim.Repo.Migrations.CreateVimLessons do
  use Ecto.Migration

  def change do
    create table(:vim_lessons) do
      add :slug, :string, null: false
      add :title, :string, null: false
      add :category, :string, null: false
      add :difficulty, :integer, null: false, default: 1
      add :order_index, :integer, null: false, default: 0
      add :description, :text
      add :initial_text, :text, null: false
      add :expected_text, :text, null: false
      add :hint, :text
      add :primary_keys, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vim_lessons, [:slug])
    create index(:vim_lessons, [:category, :order_index])
  end
end
