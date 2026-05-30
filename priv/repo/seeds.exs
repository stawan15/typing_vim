# Vim lesson seeds — run with: mix run priv/repo/seeds.exs
alias TypingVim.Repo
alias TypingVim.Vim.Lesson
import Ecto.Query

lessons = [
  # ─── MOTION ───
  %{
    slug: "motion-line-end",
    title: "Jump to end of line",
    category: "motion",
    difficulty: 1,
    order_index: 10,
    description: "Move the cursor to the last character of the line, then enter a `!` there.",
    initial_text: "place a bang at the end of this line",
    expected_text: "place a bang at the end of this line!",
    hint: "Use `$` to jump to end of line, then `a` to append after cursor.",
    primary_keys: "$ a"
  },
  %{
    slug: "motion-line-start",
    title: "Jump to start of line",
    category: "motion",
    difficulty: 1,
    order_index: 20,
    description: "Insert `>>> ` at the very beginning of the line.",
    initial_text: "the quick brown fox",
    expected_text: ">>> the quick brown fox",
    hint: "Use `0` (or `^`) to jump to line start, then `i` to insert before cursor.",
    primary_keys: "0 i"
  },
  %{
    slug: "motion-word-forward",
    title: "Word motion: forward",
    category: "motion",
    difficulty: 1,
    order_index: 30,
    description: "Delete the third word (`world`).",
    initial_text: "hello brave world today",
    expected_text: "hello brave  today",
    hint: "Use `w` to jump word-by-word, then `dw` to delete a word.",
    primary_keys: "w dw"
  },
  %{
    slug: "motion-goto-line",
    title: "Goto last line",
    category: "motion",
    difficulty: 2,
    order_index: 40,
    description: "Append `END` on a new line at the very bottom of the file.",
    initial_text: "line one\nline two\nline three",
    expected_text: "line one\nline two\nline three\nEND",
    hint: "`G` jumps to last line, then `o` opens a new line below.",
    primary_keys: "G o"
  },

  # ─── DELETE ───
  %{
    slug: "delete-word",
    title: "Delete a word",
    category: "delete",
    difficulty: 1,
    order_index: 110,
    description: "Remove the word `bad` (including the trailing space).",
    initial_text: "this bad sentence needs cleanup",
    expected_text: "this sentence needs cleanup",
    hint: "Position cursor on `bad`, then `dw` deletes word + trailing space.",
    primary_keys: "dw"
  },
  %{
    slug: "delete-line",
    title: "Delete a whole line",
    category: "delete",
    difficulty: 1,
    order_index: 120,
    description: "Delete the middle line entirely.",
    initial_text: "keep this\nDELETE ME\nkeep this too",
    expected_text: "keep this\nkeep this too",
    hint: "Move to the line, then `dd` deletes the entire line.",
    primary_keys: "dd"
  },
  %{
    slug: "delete-to-end",
    title: "Delete to end of line",
    category: "delete",
    difficulty: 2,
    order_index: 130,
    description: "Delete everything after `hello `.",
    initial_text: "hello unwanted trailing garbage",
    expected_text: "hello ",
    hint: "Position after the space, then `D` deletes from cursor to end of line.",
    primary_keys: "D"
  },

  # ─── CHANGE ───
  %{
    slug: "change-word",
    title: "Change a word",
    category: "change",
    difficulty: 2,
    order_index: 210,
    description: "Change `slow` to `fast`.",
    initial_text: "the slow fox jumps",
    expected_text: "the fast fox jumps",
    hint: "On `slow`, type `cw` then `fast` then Esc.",
    primary_keys: "cw"
  },
  %{
    slug: "change-inside-quotes",
    title: "Change inside quotes",
    category: "change",
    difficulty: 2,
    order_index: 220,
    description: "Change the quoted text to `world`.",
    initial_text: "echo \"hello\"",
    expected_text: "echo \"world\"",
    hint: "`ci\"` changes everything inside the surrounding double quotes.",
    primary_keys: "ci\""
  },
  %{
    slug: "change-inside-parens",
    title: "Change inside parens",
    category: "change",
    difficulty: 2,
    order_index: 230,
    description: "Replace the argument with `42`.",
    initial_text: "compute(old_value)",
    expected_text: "compute(42)",
    hint: "`ci(` (or `ci)`) changes content inside parentheses.",
    primary_keys: "ci("
  },

  # ─── YANK / PASTE ───
  %{
    slug: "yank-paste-line",
    title: "Duplicate a line",
    category: "yank",
    difficulty: 2,
    order_index: 310,
    description: "Duplicate the line so it appears twice.",
    initial_text: "duplicate me",
    expected_text: "duplicate me\nduplicate me",
    hint: "`yy` yanks the line, `p` pastes below.",
    primary_keys: "yy p"
  },

  # ─── INSERT ───
  %{
    slug: "insert-open-below",
    title: "Open new line below",
    category: "insert",
    difficulty: 1,
    order_index: 410,
    description: "Add a new line `second` below.",
    initial_text: "first",
    expected_text: "first\nsecond",
    hint: "`o` opens new line below and enters insert mode.",
    primary_keys: "o"
  },
  %{
    slug: "insert-append-end",
    title: "Append at end of line",
    category: "insert",
    difficulty: 1,
    order_index: 420,
    description: "Append `;` at the end of the line.",
    initial_text: "let x = 1",
    expected_text: "let x = 1;",
    hint: "`A` jumps to end of line + enters insert mode.",
    primary_keys: "A"
  },

  # ─── SEARCH / REPLACE ───
  %{
    slug: "replace-char",
    title: "Replace a single character",
    category: "replace",
    difficulty: 1,
    order_index: 510,
    description: "Change the `X` to `O`.",
    initial_text: "tic tac tXe",
    expected_text: "tic tac tOe",
    hint: "Position on `X`, press `r` then `O`.",
    primary_keys: "r"
  },
  %{
    slug: "substitute-all",
    title: "Substitute all occurrences",
    category: "replace",
    difficulty: 3,
    order_index: 520,
    description: "Replace every `foo` with `bar`.",
    initial_text: "foo and foo and foo again",
    expected_text: "bar and bar and bar again",
    hint: "Use `:%s/foo/bar/g` to substitute every occurrence in the file.",
    primary_keys: ":%s/foo/bar/g"
  }
]

now = DateTime.utc_now() |> DateTime.truncate(:second)

Enum.each(lessons, fn attrs ->
  case Repo.get_by(Lesson, slug: attrs.slug) do
    nil ->
      %Lesson{}
      |> Lesson.changeset(attrs)
      |> Repo.insert!()

    existing ->
      existing
      |> Lesson.changeset(attrs)
      |> Repo.update!()
  end
end)

count = Repo.aggregate(from(l in Lesson), :count, :id)
IO.puts("✓ seeded #{count} vim lessons (now=#{now})")
