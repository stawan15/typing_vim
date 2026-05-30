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
  },
  %{
    slug: "substitute-confirm",
    title: "Substitute first match only",
    category: "replace",
    difficulty: 2,
    order_index: 530,
    description: "Replace the first `cat` with `dog`.",
    initial_text: "cat cat cat",
    expected_text: "dog cat cat",
    hint: "Without `g` flag, `:s/cat/dog/` replaces only the first match on the current line.",
    primary_keys: ":s/cat/dog/"
  },

  # ─── MORE MOTION ───
  %{
    slug: "motion-find-char",
    title: "Find character with f",
    category: "motion",
    difficulty: 2,
    order_index: 50,
    description: "Move cursor to the `@` and delete it.",
    initial_text: "send mail to user@example.com please",
    expected_text: "send mail to userexample.com please",
    hint: "`f@` jumps to next `@`, then `x` deletes the character under cursor.",
    primary_keys: "f@ x"
  },
  %{
    slug: "motion-till-char",
    title: "Till character with t",
    category: "motion",
    difficulty: 2,
    order_index: 60,
    description: "Delete from cursor up to (but not including) the `.`.",
    initial_text: "remove all of this.keep this",
    expected_text: ".keep this",
    hint: "`dt.` deletes from cursor till (but not including) the `.` character.",
    primary_keys: "dt."
  },
  %{
    slug: "motion-paragraph",
    title: "Paragraph jump",
    category: "motion",
    difficulty: 3,
    order_index: 70,
    description: "Delete the entire middle paragraph (the second block).",
    initial_text:
      "first paragraph here\n\nmiddle paragraph\nto remove entirely\n\nlast paragraph",
    expected_text: "first paragraph here\n\nlast paragraph",
    hint: "Use `}` to jump to next paragraph, then `d}` deletes one paragraph.",
    primary_keys: "} d}"
  },
  %{
    slug: "motion-matching-bracket",
    title: "Jump to matching bracket",
    category: "motion",
    difficulty: 3,
    order_index: 80,
    description: "Delete everything between the braces (and the braces themselves).",
    initial_text: "function() { remove all of this }",
    expected_text: "function() ",
    hint: "Position on `{`, then `d%` deletes from cursor to matching bracket.",
    primary_keys: "d%"
  },

  # ─── MORE DELETE ───
  %{
    slug: "delete-char",
    title: "Delete a single character",
    category: "delete",
    difficulty: 1,
    order_index: 140,
    description: "Remove the typo letter `z` from `hellzo`.",
    initial_text: "hellzo world",
    expected_text: "hello world",
    hint: "Position on `z`, then `x` deletes the char under cursor.",
    primary_keys: "x"
  },
  %{
    slug: "delete-inside-word",
    title: "Delete inside word",
    category: "delete",
    difficulty: 2,
    order_index: 150,
    description: "Remove `oldname` regardless of cursor position on it.",
    initial_text: "var oldname = 42",
    expected_text: "var  = 42",
    hint: "From anywhere on the word, `diw` deletes the inner word.",
    primary_keys: "diw"
  },
  %{
    slug: "delete-multiple-lines",
    title: "Delete multiple lines",
    category: "delete",
    difficulty: 2,
    order_index: 160,
    description: "Delete the next 3 lines starting from `line two`.",
    initial_text: "line one\nline two\nline three\nline four\nline five",
    expected_text: "line one\nline five",
    hint: "Position on `line two`, then `3dd` deletes 3 lines at once.",
    primary_keys: "3dd"
  },
  %{
    slug: "delete-inside-quotes",
    title: "Delete inside quotes",
    category: "delete",
    difficulty: 2,
    order_index: 170,
    description: "Empty out the string content (keep the quotes).",
    initial_text: "print(\"hello world\")",
    expected_text: "print(\"\")",
    hint: "`di\"` deletes everything inside the double quotes.",
    primary_keys: "di\""
  },

  # ─── MORE CHANGE ───
  %{
    slug: "change-line",
    title: "Change a whole line",
    category: "change",
    difficulty: 2,
    order_index: 240,
    description: "Replace the entire second line with `replaced`.",
    initial_text: "keep this\nold content here\nkeep this too",
    expected_text: "keep this\nreplaced\nkeep this too",
    hint: "On the line, `cc` deletes it and enters insert mode.",
    primary_keys: "cc"
  },
  %{
    slug: "change-to-end",
    title: "Change to end of line",
    category: "change",
    difficulty: 2,
    order_index: 250,
    description: "Change everything after `let x = ` to `100`.",
    initial_text: "let x = old_value + extra",
    expected_text: "let x = 100",
    hint: "Position after `= `, then `C` changes from cursor to end of line.",
    primary_keys: "C"
  },
  %{
    slug: "change-inside-brackets",
    title: "Change inside brackets",
    category: "change",
    difficulty: 2,
    order_index: 260,
    description: "Replace the array contents with `1, 2, 3`.",
    initial_text: "let nums = [old, stale, values]",
    expected_text: "let nums = [1, 2, 3]",
    hint: "`ci[` (or `ci]`) changes everything inside square brackets.",
    primary_keys: "ci["
  },

  # ─── MORE YANK / PASTE ───
  %{
    slug: "yank-word",
    title: "Yank and paste a word",
    category: "yank",
    difficulty: 2,
    order_index: 320,
    description: "Duplicate the word `hello` so it appears twice.",
    initial_text: "hello",
    expected_text: "hellohello",
    hint: "`yiw` yanks the inner word, `p` pastes after cursor.",
    primary_keys: "yiw p"
  },
  %{
    slug: "yank-multiple-lines",
    title: "Yank 3 lines",
    category: "yank",
    difficulty: 3,
    order_index: 330,
    description: "Copy the first 3 lines and paste them at the end.",
    initial_text: "alpha\nbeta\ngamma\n---",
    expected_text: "alpha\nbeta\ngamma\n---\nalpha\nbeta\ngamma",
    hint: "From line 1: `3yy` yanks 3 lines, `G` to last line, `p` to paste.",
    primary_keys: "3yy G p"
  },

  # ─── MORE INSERT ───
  %{
    slug: "insert-open-above",
    title: "Open new line above",
    category: "insert",
    difficulty: 1,
    order_index: 430,
    description: "Insert `// header` above the existing line.",
    initial_text: "function main() {}",
    expected_text: "// header\nfunction main() {}",
    hint: "`O` (capital) opens a new line above and enters insert mode.",
    primary_keys: "O"
  },
  %{
    slug: "insert-before-line",
    title: "Insert at start of line",
    category: "insert",
    difficulty: 1,
    order_index: 440,
    description: "Prefix the line with `# ` (markdown heading).",
    initial_text: "Title",
    expected_text: "# Title",
    hint: "`I` (capital) jumps to first non-blank + enters insert mode.",
    primary_keys: "I"
  },

  # ─── VISUAL MODE ───
  %{
    slug: "visual-delete-word",
    title: "Visual: select and delete",
    category: "visual",
    difficulty: 2,
    order_index: 610,
    description: "Delete the word `REMOVE` using visual mode.",
    initial_text: "keep REMOVE keep",
    expected_text: "keep  keep",
    hint: "On `R`, press `v` to enter visual, `e` to extend to end of word, `d` to delete.",
    primary_keys: "v e d"
  },
  %{
    slug: "visual-line-delete",
    title: "Visual line: select lines",
    category: "visual",
    difficulty: 2,
    order_index: 620,
    description: "Delete the middle 2 lines using line-visual mode.",
    initial_text: "header\nremove this\nand this too\nfooter",
    expected_text: "header\nfooter",
    hint: "On line 2, `V` enters line-visual, `j` extends down, `d` deletes.",
    primary_keys: "V j d"
  },
  %{
    slug: "visual-uppercase",
    title: "Visual: uppercase selection",
    category: "visual",
    difficulty: 2,
    order_index: 630,
    description: "Convert `hello` to uppercase.",
    initial_text: "say hello world",
    expected_text: "say HELLO world",
    hint: "On `h`, `v` to enter visual, `e` to end of word, `U` to uppercase.",
    primary_keys: "v e U"
  },

  # ─── ADVANCED ───
  %{
    slug: "indent-line",
    title: "Indent a line",
    category: "advanced",
    difficulty: 2,
    order_index: 710,
    description: "Indent the middle line by one shift-width.",
    initial_text: "function f() {\nreturn 42\n}",
    expected_text: "function f() {\n  return 42\n}",
    hint: "On the line, `>>` indents the line right.",
    primary_keys: ">>"
  },
  %{
    slug: "join-lines",
    title: "Join two lines",
    category: "advanced",
    difficulty: 1,
    order_index: 720,
    description: "Join the two lines into one (separated by a space).",
    initial_text: "hello\nworld",
    expected_text: "hello world",
    hint: "`J` (capital) joins the line below to the current line.",
    primary_keys: "J"
  },
  %{
    slug: "repeat-last",
    title: "Repeat last change",
    category: "advanced",
    difficulty: 3,
    order_index: 730,
    description: "Delete both occurrences of `BAD` using `dw` once + `.` to repeat.",
    initial_text: "BAD keep BAD keep",
    expected_text: "keep keep",
    hint: "On first `BAD`: `dw` deletes it. Move to next `BAD` (use `w`), then `.` repeats `dw`.",
    primary_keys: "dw w ."
  },
  %{
    slug: "swap-case",
    title: "Swap case of a word",
    category: "advanced",
    difficulty: 2,
    order_index: 740,
    description: "Swap the case of every letter in `Hello`.",
    initial_text: "Hello world",
    expected_text: "hELLO world",
    hint: "On `H`, `g~iw` swaps the case of the inner word (or use `~` per char).",
    primary_keys: "g~iw"
  },

  # ─── HARD: REGEX / SUBSTITUTE ───
  %{
    slug: "regex-capture-swap",
    title: "Swap first and last word (regex)",
    category: "regex",
    difficulty: 4,
    order_index: 810,
    description: "Swap the two words using a regex substitution with capture groups.",
    initial_text: "alice bob",
    expected_text: "bob alice",
    hint: "Try `:s/\\v(\\w+) (\\w+)/\\2 \\1/` — `\\v` enables very-magic regex.",
    primary_keys: ":s/\\v(\\w+) (\\w+)/\\2 \\1/"
  },
  %{
    slug: "regex-strip-trailing-ws",
    title: "Strip trailing whitespace (regex)",
    category: "regex",
    difficulty: 4,
    order_index: 820,
    description: "Remove all trailing spaces at end of each line.",
    initial_text: "first line   \nsecond  \nthird    ",
    expected_text: "first line\nsecond\nthird",
    hint: "`:%s/ \\+$//` removes one-or-more spaces at end of line on every line.",
    primary_keys: ":%s/ \\+$//"
  },
  %{
    slug: "regex-add-line-numbers",
    title: "Prefix each line with its number",
    category: "regex",
    difficulty: 5,
    order_index: 830,
    description: "Add the line number followed by `: ` at the start of every line.",
    initial_text: "alpha\nbeta\ngamma",
    expected_text: "1: alpha\n2: beta\n3: gamma",
    hint: "Use a global substitute with `\\=line('.')`: `:%s/^/\\=line('.').': '/`",
    primary_keys: ":%s/^/\\=line('.').': '/"
  },

  # ─── HARD: SORT / FILTER ───
  %{
    slug: "sort-lines-asc",
    title: "Sort lines alphabetically",
    category: "ex",
    difficulty: 3,
    order_index: 910,
    description: "Sort all lines in ascending alphabetical order.",
    initial_text: "delta\nalpha\ncharlie\nbravo",
    expected_text: "alpha\nbravo\ncharlie\ndelta",
    hint: "`:%sort` or `:sort` (with the whole file selected) sorts lines.",
    primary_keys: ":sort"
  },
  %{
    slug: "sort-lines-unique",
    title: "Sort + remove duplicates",
    category: "ex",
    difficulty: 4,
    order_index: 920,
    description: "Sort and dedupe so each name appears only once.",
    initial_text: "bob\nalice\nbob\ncarol\nalice",
    expected_text: "alice\nbob\ncarol",
    hint: "`:sort u` (or `:%sort u`) sorts and keeps only unique lines.",
    primary_keys: ":sort u"
  },
  %{
    slug: "reverse-lines",
    title: "Reverse line order",
    category: "ex",
    difficulty: 4,
    order_index: 930,
    description: "Flip the order of all lines.",
    initial_text: "one\ntwo\nthree\nfour",
    expected_text: "four\nthree\ntwo\none",
    hint: "`:g/^/m0` moves every line to the top, effectively reversing order.",
    primary_keys: ":g/^/m0"
  },

  # ─── HARD: MULTI-LINE REFACTOR ───
  %{
    slug: "refactor-rename-var",
    title: "Rename every `tmp` to `result`",
    category: "refactor",
    difficulty: 3,
    order_index: 1010,
    description: "Rename the variable consistently throughout the snippet.",
    initial_text: "let tmp = 0\nfor (i = 0; i < 10; i++) {\n  tmp = tmp + i\n}\nreturn tmp",
    expected_text:
      "let result = 0\nfor (i = 0; i < 10; i++) {\n  result = result + i\n}\nreturn result",
    hint: "`:%s/tmp/result/g` substitutes every `tmp` in the file.",
    primary_keys: ":%s/tmp/result/g"
  },
  %{
    slug: "refactor-wrap-quotes",
    title: "Wrap every line in double quotes",
    category: "refactor",
    difficulty: 4,
    order_index: 1020,
    description: "Surround each line with `\"...\"`.",
    initial_text: "apple\nbanana\ncherry",
    expected_text: "\"apple\"\n\"banana\"\n\"cherry\"",
    hint: "`:%s/^\\(.*\\)$/\"\\1\"/` captures the whole line and wraps with quotes.",
    primary_keys: ":%s/^.*$/\"&\"/"
  },
  %{
    slug: "refactor-comment-block",
    title: "Comment out every line",
    category: "refactor",
    difficulty: 3,
    order_index: 1030,
    description: "Prefix every line with `// `.",
    initial_text: "let x = 1\nlet y = 2\nlet z = 3",
    expected_text: "// let x = 1\n// let y = 2\n// let z = 3",
    hint: "`:%s/^/\\/\\/ /` prepends `// ` to every line.",
    primary_keys: ":%s/^/\\/\\/ /"
  },

  # ─── HARD: GLOBAL COMMAND ───
  %{
    slug: "global-delete-matching",
    title: "Delete lines matching pattern",
    category: "ex",
    difficulty: 4,
    order_index: 940,
    description: "Remove every line that contains the word `DEBUG`.",
    initial_text: "info: starting\nDEBUG: x=1\ninfo: running\nDEBUG: x=2\ninfo: done",
    expected_text: "info: starting\ninfo: running\ninfo: done",
    hint: "`:g/DEBUG/d` deletes every line that matches the pattern.",
    primary_keys: ":g/DEBUG/d"
  },
  %{
    slug: "global-keep-matching",
    title: "Keep only matching lines",
    category: "ex",
    difficulty: 4,
    order_index: 950,
    description: "Keep only lines containing `KEEP`, delete the rest.",
    initial_text: "noise one\nKEEP: alpha\nnoise two\nKEEP: beta\nnoise three",
    expected_text: "KEEP: alpha\nKEEP: beta",
    hint: "`:v/KEEP/d` (inverse of `:g`) deletes every line NOT matching.",
    primary_keys: ":v/KEEP/d"
  },

  # ─── HARD: NUMBERS / INCREMENT ───
  %{
    slug: "increment-number",
    title: "Increment a number",
    category: "advanced",
    difficulty: 2,
    order_index: 750,
    description: "Bump the version from `41` to `42` using a single keystroke.",
    initial_text: "version = 41",
    expected_text: "version = 42",
    hint: "Position on (or before) the number, then `Ctrl-A` increments it.",
    primary_keys: "Ctrl-A"
  },

  # ─── HARD: MARKS / JUMPS ───
  %{
    slug: "mark-and-return",
    title: "Use a mark to swap two regions",
    category: "advanced",
    difficulty: 5,
    order_index: 760,
    description: "Move the `END` marker to the very top of the file.",
    initial_text: "line one\nline two\nline three\nEND",
    expected_text: "END\nline one\nline two\nline three",
    hint: "On `END` line: `dd` to cut, `gg` to top, `P` to paste before.",
    primary_keys: "dd gg P"
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
