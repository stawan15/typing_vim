defmodule TypingVim.Repo.Migrations.CreateTypingResults do
  use Ecto.Migration

  def change do
    create table(:typing_results) do
      add :guest_id, :string, null: false
      add :display_name, :string
      add :mode, :string, null: false
      add :duration_sec, :integer, null: false
      add :word_count, :integer, null: false
      add :wpm, :float, null: false
      add :raw_wpm, :float, null: false
      add :accuracy, :float, null: false
      add :correct_chars, :integer, null: false
      add :incorrect_chars, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:typing_results, [:guest_id])
    create index(:typing_results, [:wpm])
    create index(:typing_results, [:mode, :duration_sec, :wpm])
  end
end
