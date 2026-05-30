defmodule TypingVim.Vim.Attempt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vim_attempts" do
    field :guest_id, :string
    field :success, :boolean, default: false
    field :keystroke_count, :integer
    field :time_ms, :integer

    belongs_to :lesson, TypingVim.Vim.Lesson

    timestamps(type: :utc_datetime)
  end

  def changeset(attempt, attrs) do
    attempt
    |> cast(attrs, [:guest_id, :lesson_id, :success, :keystroke_count, :time_ms])
    |> validate_required([:guest_id, :lesson_id, :success])
  end
end
