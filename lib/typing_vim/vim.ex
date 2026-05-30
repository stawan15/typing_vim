defmodule TypingVim.Vim do
  @moduledoc """
  Context for Vim lessons + attempts.
  """
  import Ecto.Query
  alias TypingVim.Repo
  alias TypingVim.Vim.{Lesson, Attempt}

  # --- Lessons ---

  def list_lessons do
    Lesson
    |> order_by([l], asc: l.order_index)
    |> Repo.all()
  end

  def list_lessons_grouped do
    list_lessons()
    |> Enum.group_by(& &1.category)
  end

  def get_lesson_by_slug!(slug), do: Repo.get_by!(Lesson, slug: slug)

  def get_lesson!(id), do: Repo.get!(Lesson, id)

  def next_lesson(%Lesson{order_index: idx}) do
    Lesson
    |> where([l], l.order_index > ^idx)
    |> order_by([l], asc: l.order_index)
    |> limit(1)
    |> Repo.one()
  end

  def prev_lesson(%Lesson{order_index: idx}) do
    Lesson
    |> where([l], l.order_index < ^idx)
    |> order_by([l], desc: l.order_index)
    |> limit(1)
    |> Repo.one()
  end

  @doc "Check if the submitted text matches expected (whitespace-sensitive)."
  def check_solution(%Lesson{expected_text: expected}, submitted) do
    normalize(expected) == normalize(submitted)
  end

  defp normalize(nil), do: ""
  defp normalize(s), do: s |> String.replace("\r\n", "\n") |> String.trim_trailing()

  # --- Attempts ---

  def record_attempt(attrs) do
    %Attempt{}
    |> Attempt.changeset(attrs)
    |> Repo.insert()
  end

  def solved_lesson_ids(guest_id) do
    Attempt
    |> where([a], a.guest_id == ^guest_id and a.success == true)
    |> select([a], a.lesson_id)
    |> distinct(true)
    |> Repo.all()
    |> MapSet.new()
  end
end
