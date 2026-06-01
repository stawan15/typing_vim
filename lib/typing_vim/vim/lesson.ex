defmodule TypingVim.Vim.Lesson do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vim_lessons" do
    field :slug, :string
    field :title, :string
    field :category, :string
    field :difficulty, :integer, default: 1
    field :order_index, :integer, default: 0
    field :description, :string
    field :initial_text, :string
    field :expected_text, :string
    field :hint, :string
    field :primary_keys, :string
    field :task_type, :string, default: "edit"
    field :target_line, :integer
    field :target_col, :integer
    field :expected_keys, :string

    has_many :attempts, TypingVim.Vim.Attempt, foreign_key: :lesson_id

    timestamps(type: :utc_datetime)
  end

  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [
      :slug,
      :title,
      :category,
      :difficulty,
      :order_index,
      :description,
      :initial_text,
      :expected_text,
      :hint,
      :primary_keys,
      :task_type,
      :target_line,
      :target_col,
      :expected_keys
    ])
    |> validate_required([:slug, :title, :category, :initial_text, :expected_text])
    |> unique_constraint(:slug)
  end
end
