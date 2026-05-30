defmodule TypingVim.Repo.Migrations.CreateVimAttempts do
  use Ecto.Migration

  def change do
    create table(:vim_attempts) do
      add :guest_id, :string, null: false
      add :lesson_id, references(:vim_lessons, on_delete: :delete_all), null: false
      add :success, :boolean, null: false, default: false
      add :keystroke_count, :integer
      add :time_ms, :integer

      timestamps(type: :utc_datetime)
    end

    create index(:vim_attempts, [:guest_id])
    create index(:vim_attempts, [:lesson_id])
  end
end
