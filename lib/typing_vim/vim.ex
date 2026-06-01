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

  @doc """
  Check whether the cursor (1-indexed line, 0-indexed col) is on the
  target position for a motion lesson.
  """
  def check_motion(%Lesson{task_type: "motion", target_line: tl, target_col: tc}, line, col)
      when is_integer(tl) do
    line == tl and (is_nil(tc) or col == tc)
  end

  def check_motion(_lesson, _line, _col), do: false

  @doc """
  Compute a 0..100 similarity score between an expected vim key string
  (e.g. "11gg") and the user's actual recorded keystrokes (e.g. "1jjGgg").
  Uses normalised Levenshtein distance.
  """
  def key_similarity(nil, _), do: 0
  def key_similarity(_, nil), do: 0

  def key_similarity(expected, actual) when is_binary(expected) and is_binary(actual) do
    e = String.trim(expected)
    a = String.trim(actual)

    cond do
      e == "" ->
        0

      a == "" ->
        0

      e == a ->
        100

      true ->
        dist = levenshtein(e, a)
        max_len = max(String.length(e), String.length(a))
        pct = (1 - dist / max_len) * 100
        pct |> max(0) |> round()
    end
  end

  defp levenshtein(a, b) do
    a = String.graphemes(a)
    b = String.graphemes(b)
    do_lev(a, b, 0..length(b) |> Enum.to_list())
  end

  defp do_lev([], _b, prev), do: List.last(prev)

  defp do_lev([ca | rest_a], b, prev) do
    [first | _] = prev
    next = [first + 1]
    next = lev_row(b, prev, ca, next, 1)
    do_lev(rest_a, b, next)
  end

  defp lev_row([], _prev, _ca, acc, _i), do: Enum.reverse(acc)

  defp lev_row([cb | rest_b], prev, ca, acc, i) do
    cost = if ca == cb, do: 0, else: 1
    prev_i = Enum.at(prev, i)
    prev_i_minus = Enum.at(prev, i - 1)
    [left | _] = acc

    value =
      Enum.min([
        prev_i + 1,
        left + 1,
        prev_i_minus + cost
      ])

    lev_row(rest_b, prev, ca, [value | acc], i + 1)
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
