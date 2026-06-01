defmodule TypingVim.Repo.Migrations.AddMotionFieldsToVimLessons do
  use Ecto.Migration

  def change do
    alter table(:vim_lessons) do
      # "edit" (default) or "motion"
      add :task_type, :string, null: false, default: "edit"
      # 1-indexed line / 0-indexed column the cursor must reach for motion lessons
      add :target_line, :integer
      add :target_col, :integer
      # The expected vim key sequence (e.g. "11gg", "G", "5j"). Used for
      # similarity-scoring the user's actual keystrokes.
      add :expected_keys, :string
    end
  end
end
