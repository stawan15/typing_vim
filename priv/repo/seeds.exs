# Vim lesson seeds — run with: mix run priv/repo/seeds.exs
#
# Two task types:
#   • task_type: "motion"  → success when cursor reaches target_line / target_col.
#                            No text edit needed. Compared against expected_keys.
#   • task_type: "edit"    → success when buffer text == expected_text.
#
# Keep lessons SHORT and easy. No long `:%s/.../.../g` style commands.
alias TypingVim.Repo
alias TypingVim.Vim.Lesson
import Ecto.Query

# A reusable multi-line paragraph used for motion lessons so the cursor has
# somewhere to move. 20 lines.
movement_buffer =
  Enum.map_join(1..20, "\n", fn i ->
    "line #{String.pad_leading(Integer.to_string(i), 2)} — the quick brown fox jumps"
  end)

lessons = [
  # ────────────────────────────────────────────────────────────────────────
  # NAVIGATION — pure motion, no edits required
  # ────────────────────────────────────────────────────────────────────────
  %{
    slug: "nav-gg",
    title: "Jump to first line — gg",
    category: "navigation",
    difficulty: 1,
    order_index: 10,
    task_type: "motion",
    description: "Press `gg` to move the cursor to line 1.",
    initial_text: movement_buffer,
    expected_text: movement_buffer,
    target_line: 1,
    target_col: 0,
    expected_keys: "gg",
    hint: "`gg` jumps to the very first line.",
    primary_keys: "gg"
  },
  %{
    slug: "nav-G",
    title: "Jump to last line — Shift+G",
    category: "navigation",
    difficulty: 1,
    order_index: 20,
    task_type: "motion",
    description: "Press `G` (Shift+G) to jump to the last line.",
    initial_text: movement_buffer,
    expected_text: movement_buffer,
    target_line: 20,
    expected_keys: "G",
    hint: "Capital `G` (Shift+G) jumps straight to the last line.",
    primary_keys: "G"
  },
  %{
    slug: "nav-11gg",
    title: "Goto line 11 — 11gg",
    category: "navigation",
    difficulty: 2,
    order_index: 30,
    task_type: "motion",
    description: "Land the cursor on line 11. Try `11gg` (or `11G`).",
    initial_text: movement_buffer,
    expected_text: movement_buffer,
    target_line: 11,
    expected_keys: "11gg",
    hint: "Type the number first, then `gg`: e.g. `11gg`.",
    primary_keys: "11gg"
  },
  %{
    slug: "nav-5gg",
    title: "Goto line 5 — 5gg",
    category: "navigation",
    difficulty: 2,
    order_index: 40,
    task_type: "motion",
    description: "Move to line 5.",
    initial_text: movement_buffer,
    expected_text: movement_buffer,
    target_line: 5,
    expected_keys: "5gg",
    hint: "`5gg` (or `5G`) — number + gg.",
    primary_keys: "5gg"
  },
  %{
    slug: "nav-3j",
    title: "Down 3 lines — 3j",
    category: "navigation",
    difficulty: 1,
    order_index: 50,
    task_type: "motion",
    description: "From line 1, move down 3 lines (to line 4).",
    initial_text: movement_buffer,
    expected_text: movement_buffer,
    target_line: 4,
    expected_keys: "3j",
    hint: "Numbers prefix motions. `3j` = down 3 times.",
    primary_keys: "3j"
  },
  %{
    slug: "nav-5k",
    title: "Up 5 lines — 5k from bottom",
    category: "navigation",
    difficulty: 2,
    order_index: 60,
    task_type: "motion",
    description: "From the bottom, go up 5 lines. First `G`, then `5k`.",
    initial_text: movement_buffer,
    expected_text: movement_buffer,
    target_line: 15,
    expected_keys: "G5k",
    hint: "`G` to last line, then `5k` moves up 5.",
    primary_keys: "G 5k"
  },
  %{
    slug: "nav-line-end",
    title: "End of line — $",
    category: "navigation",
    difficulty: 1,
    order_index: 70,
    task_type: "motion",
    description: "On line 1, press `$` to jump to the end of the line.",
    initial_text: "press dollar to reach the end",
    expected_text: "press dollar to reach the end",
    target_line: 1,
    target_col: 28,
    expected_keys: "$",
    hint: "`$` = end of line. `0` = start of line.",
    primary_keys: "$"
  },
  %{
    slug: "nav-line-start",
    title: "Start of line — 0",
    category: "navigation",
    difficulty: 1,
    order_index: 80,
    task_type: "motion",
    description: "Go to column 0 of the line.",
    initial_text: "    indented line — go to col 0",
    expected_text: "    indented line — go to col 0",
    target_line: 1,
    target_col: 0,
    expected_keys: "0",
    hint: "`0` goes to column 0. `^` goes to first non-whitespace.",
    primary_keys: "0"
  },
  %{
    slug: "nav-word-w",
    title: "Next word — w",
    category: "navigation",
    difficulty: 1,
    order_index: 90,
    task_type: "motion",
    description: "Press `w` three times to jump to the 4th word.",
    initial_text: "alpha beta gamma delta epsilon",
    expected_text: "alpha beta gamma delta epsilon",
    target_line: 1,
    target_col: 17,
    expected_keys: "www",
    hint: "`w` jumps forward by word. `3w` does it in one step.",
    primary_keys: "w w w (or 3w)"
  },
  %{
    slug: "nav-word-b",
    title: "Back a word — b",
    category: "navigation",
    difficulty: 1,
    order_index: 100,
    task_type: "motion",
    description: "Jump to end of line with `$`, then `b` back one word.",
    initial_text: "alpha beta gamma delta",
    expected_text: "alpha beta gamma delta",
    target_line: 1,
    target_col: 17,
    expected_keys: "$b",
    hint: "`$` to line end, then `b` jumps to start of previous word.",
    primary_keys: "$ b"
  },
  %{
    slug: "nav-find-char",
    title: "Find char — f@",
    category: "navigation",
    difficulty: 2,
    order_index: 110,
    task_type: "motion",
    description: "Use `f@` to jump straight to the `@`.",
    initial_text: "send mail to user@example.com",
    expected_text: "send mail to user@example.com",
    target_line: 1,
    target_col: 17,
    expected_keys: "f@",
    hint: "`f<char>` finds the next occurrence of <char> on the line.",
    primary_keys: "f@"
  },
  %{
    slug: "nav-paragraph",
    title: "Next paragraph — }",
    category: "navigation",
    difficulty: 2,
    order_index: 120,
    task_type: "motion",
    description: "Jump to the blank line between the two paragraphs.",
    initial_text: "first paragraph here\nstill the first\n\nsecond paragraph\nlast line",
    expected_text: "first paragraph here\nstill the first\n\nsecond paragraph\nlast line",
    target_line: 3,
    expected_keys: "}",
    hint: "`}` jumps to next paragraph break, `{` jumps to previous.",
    primary_keys: "}"
  },

  # ────────────────────────────────────────────────────────────────────────
  # INSERT — getting into insert mode
  # ────────────────────────────────────────────────────────────────────────
  %{
    slug: "insert-append-end",
    title: "Append at end of line — A",
    category: "insert",
    difficulty: 1,
    order_index: 210,
    task_type: "edit",
    description: "Append `;` at the end of the line.",
    initial_text: "let x = 1",
    expected_text: "let x = 1;",
    hint: "`A` jumps to end of line and enters insert mode in one keystroke.",
    primary_keys: "A"
  },
  %{
    slug: "insert-open-below",
    title: "Open new line below — o",
    category: "insert",
    difficulty: 1,
    order_index: 220,
    task_type: "edit",
    description: "Add a new line `second` below.",
    initial_text: "first",
    expected_text: "first\nsecond",
    hint: "`o` opens a new line below + enters insert mode.",
    primary_keys: "o"
  },
  %{
    slug: "insert-open-above",
    title: "Open new line above — O",
    category: "insert",
    difficulty: 1,
    order_index: 230,
    task_type: "edit",
    description: "Insert `// header` above the existing line.",
    initial_text: "function main() {}",
    expected_text: "// header\nfunction main() {}",
    hint: "Capital `O` opens a line above.",
    primary_keys: "O"
  },
  %{
    slug: "insert-line-start",
    title: "Insert at line start — I",
    category: "insert",
    difficulty: 1,
    order_index: 240,
    task_type: "edit",
    description: "Prefix with `# `.",
    initial_text: "Title",
    expected_text: "# Title",
    hint: "Capital `I` jumps to first non-blank + insert mode.",
    primary_keys: "I"
  },

  # ────────────────────────────────────────────────────────────────────────
  # DELETE — short, single-keystroke commands
  # ────────────────────────────────────────────────────────────────────────
  %{
    slug: "delete-char",
    title: "Delete a char — x",
    category: "delete",
    difficulty: 1,
    order_index: 310,
    task_type: "edit",
    description: "Remove the typo `z`.",
    initial_text: "hellzo world",
    expected_text: "hello world",
    hint: "`x` deletes the char under the cursor.",
    primary_keys: "x"
  },
  %{
    slug: "delete-word",
    title: "Delete a word — dw",
    category: "delete",
    difficulty: 1,
    order_index: 320,
    task_type: "edit",
    description: "Remove the word `bad`.",
    initial_text: "this bad sentence needs cleanup",
    expected_text: "this sentence needs cleanup",
    hint: "Position on `bad`, then `dw` deletes a word.",
    primary_keys: "dw"
  },
  %{
    slug: "delete-line",
    title: "Delete a line — dd",
    category: "delete",
    difficulty: 1,
    order_index: 330,
    task_type: "edit",
    description: "Delete the middle line entirely.",
    initial_text: "keep this\nDELETE ME\nkeep this too",
    expected_text: "keep this\nkeep this too",
    hint: "`dd` deletes the entire current line.",
    primary_keys: "dd"
  },
  %{
    slug: "delete-to-end",
    title: "Delete to end — D",
    category: "delete",
    difficulty: 2,
    order_index: 340,
    task_type: "edit",
    description: "Delete everything after `hello `.",
    initial_text: "hello unwanted trailing garbage",
    expected_text: "hello ",
    hint: "`D` (capital) deletes from cursor to end of line.",
    primary_keys: "D"
  },
  %{
    slug: "delete-inside-word",
    title: "Delete inside word — diw",
    category: "delete",
    difficulty: 2,
    order_index: 350,
    task_type: "edit",
    description: "Remove `oldname` from anywhere on the word.",
    initial_text: "var oldname = 42",
    expected_text: "var  = 42",
    hint: "`diw` deletes the inner word regardless of cursor position on it.",
    primary_keys: "diw"
  },

  # ────────────────────────────────────────────────────────────────────────
  # CHANGE — c-commands
  # ────────────────────────────────────────────────────────────────────────
  %{
    slug: "change-word",
    title: "Change a word — cw",
    category: "change",
    difficulty: 1,
    order_index: 410,
    task_type: "edit",
    description: "Change `slow` to `fast`.",
    initial_text: "the slow fox jumps",
    expected_text: "the fast fox jumps",
    hint: "On `slow`: `cw` then type `fast` then Esc.",
    primary_keys: "cw"
  },
  %{
    slug: "change-line",
    title: "Change a line — cc",
    category: "change",
    difficulty: 1,
    order_index: 420,
    task_type: "edit",
    description: "Replace the middle line with `replaced`.",
    initial_text: "keep this\nold content here\nkeep this too",
    expected_text: "keep this\nreplaced\nkeep this too",
    hint: "`cc` deletes the line and drops you into insert mode.",
    primary_keys: "cc"
  },
  %{
    slug: "change-inside-quotes",
    title: "Change inside quotes — ci\"",
    category: "change",
    difficulty: 2,
    order_index: 430,
    task_type: "edit",
    description: "Change the quoted text to `world`.",
    initial_text: "echo \"hello\"",
    expected_text: "echo \"world\"",
    hint: "`ci\"` changes everything inside the surrounding double quotes.",
    primary_keys: "ci\""
  },

  # ────────────────────────────────────────────────────────────────────────
  # YANK / PASTE
  # ────────────────────────────────────────────────────────────────────────
  %{
    slug: "yank-paste-line",
    title: "Duplicate a line — yyp",
    category: "yank",
    difficulty: 1,
    order_index: 510,
    task_type: "edit",
    description: "Duplicate the line.",
    initial_text: "duplicate me",
    expected_text: "duplicate me\nduplicate me",
    hint: "`yy` yanks the line, `p` pastes below.",
    primary_keys: "yyp"
  },

  # ────────────────────────────────────────────────────────────────────────
  # REPLACE — single-key
  # ────────────────────────────────────────────────────────────────────────
  %{
    slug: "replace-char",
    title: "Replace one char — r",
    category: "replace",
    difficulty: 1,
    order_index: 610,
    task_type: "edit",
    description: "Change the `X` to `O`.",
    initial_text: "tic tac tXe",
    expected_text: "tic tac tOe",
    hint: "Position on `X`, press `r` then `O`.",
    primary_keys: "rO"
  },

  # ────────────────────────────────────────────────────────────────────────
  # VISUAL — small selections
  # ────────────────────────────────────────────────────────────────────────
  %{
    slug: "visual-line-delete",
    title: "Visual line: delete — Vj d",
    category: "visual",
    difficulty: 2,
    order_index: 710,
    task_type: "edit",
    description: "Delete the middle two lines.",
    initial_text: "header\nremove\nthis too\nfooter",
    expected_text: "header\nfooter",
    hint: "On line 2: `V` (line-visual), `j` extends down, `d` deletes.",
    primary_keys: "Vjd"
  },

  # ────────────────────────────────────────────────────────────────────────
  # SMALL ADVANCED — single-key power
  # ────────────────────────────────────────────────────────────────────────
  %{
    slug: "join-lines",
    title: "Join lines — J",
    category: "advanced",
    difficulty: 1,
    order_index: 810,
    task_type: "edit",
    description: "Join the two lines into one.",
    initial_text: "hello\nworld",
    expected_text: "hello world",
    hint: "Capital `J` joins the line below with a space.",
    primary_keys: "J"
  },
  %{
    slug: "repeat-last",
    title: "Repeat last — .",
    category: "advanced",
    difficulty: 2,
    order_index: 820,
    task_type: "edit",
    description: "Delete both `BAD` words using `dw` once + `.` to repeat.",
    initial_text: "BAD keep BAD keep",
    expected_text: "keep keep",
    hint: "First `BAD`: `dw`. Move with `w` to next `BAD`, then `.` to repeat.",
    primary_keys: "dw w ."
  }
]

now = DateTime.utc_now() |> DateTime.truncate(:second)

# Wipe any old lessons that are no longer in the seed list, so we don't carry
# stale long-command lessons from earlier seeds.
seed_slugs = Enum.map(lessons, & &1.slug)

Repo.delete_all(from l in Lesson, where: l.slug not in ^seed_slugs)

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
