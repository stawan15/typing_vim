import { EditorView, basicSetup } from "codemirror";
import { EditorState } from "@codemirror/state";
import { vim, Vim } from "@replit/codemirror-vim";
import {
  keymap,
  lineNumbers,
  highlightActiveLine,
  highlightActiveLineGutter,
} from "@codemirror/view";
import { syntaxHighlighting, defaultHighlightStyle } from "@codemirror/language";
import { keySound } from "./sound";

// ─── Custom :ex commands and gX mappings ────────────────────────────────────
// These are *global* on the Vim singleton — defining them more than once is a
// no-op (idempotent). We dispatch CustomEvents that the active VimEditor hook
// listens to and translates into push_event calls to the LiveView.
function defineVimCommands() {
  if (window.__vimExDefined) return;
  window.__vimExDefined = true;

  const fire = (name, detail = {}) =>
    window.dispatchEvent(new CustomEvent(name, { detail }));

  // :w / :write — check current solution
  Vim.defineEx("write", "w", () => fire("vim:cmd-check"));
  // :n / :next — go to next lesson
  Vim.defineEx("next", "n", () => fire("vim:cmd-next"));
  // :prev / :p / :N — go to previous lesson
  Vim.defineEx("prev", "p", () => fire("vim:cmd-prev"));
  Vim.defineEx("Next", "N", () => fire("vim:cmd-prev"));
  // :reset / :r — reset buffer
  Vim.defineEx("reset", "r", () => fire("vim:cmd-reset"));
  // :help / :h — toggle hint
  Vim.defineEx("help", "h", () => fire("vim:cmd-hint"));
  // :q / :quit — back to lesson list
  Vim.defineEx("quit", "q", () => fire("vim:cmd-quit"));
  Vim.defineEx("wq", "wq", () => {
    fire("vim:cmd-check");
    setTimeout(() => fire("vim:cmd-next"), 200);
  });

  // Normal-mode shortcuts (vim-style "g" prefix).
  // These use `Vim.map` so they work without typing `:`.
  Vim.map("gn", ":next<CR>", "normal");
  Vim.map("gp", ":prev<CR>", "normal");
  Vim.map("gr", ":reset<CR>", "normal");
  Vim.map("gh", ":help<CR>", "normal");
  Vim.map("gq", ":quit<CR>", "normal");
}

// Custom vim-flavoured CodeMirror theme — gruvbox-dark inspired
const vimTheme = EditorView.theme(
  {
    "&": {
      fontSize: "20px",
      color: "#ebdbb2",
      backgroundColor: "#1d2021",
      height: "100%",
    },
    ".cm-content": {
      caretColor: "#fabd2f",
      fontFamily:
        "'JetBrains Mono', 'Fira Code', ui-monospace, SFMono-Regular, Menlo, monospace",
      padding: "12px 0",
      lineHeight: "1.55",
    },
    ".cm-editor": { minHeight: "380px" },
    ".cm-editor.cm-focused": { outline: "none" },
    ".cm-gutters": {
      backgroundColor: "#1d2021",
      color: "#665c54",
      border: "none",
      borderRight: "1px solid #3c3836",
      paddingRight: "8px",
    },
    ".cm-activeLineGutter": { color: "#fabd2f", backgroundColor: "transparent" },
    ".cm-activeLine": { backgroundColor: "#282828" },
    ".cm-cursor, .cm-dropCursor": {
      borderLeftColor: "#fabd2f",
      borderLeftWidth: "2px",
    },
    ".cm-fat-cursor": {
      background: "#fabd2f !important",
      color: "#1d2021 !important",
      outline: "none !important",
    },
    "&:not(.cm-focused) .cm-fat-cursor": {
      background: "transparent !important",
      outline: "2px solid #fabd2f !important",
    },
    ".cm-selectionBackground, ::selection": { backgroundColor: "#504945" },
    ".cm-line": { padding: "0 16px" },
    ".cm-panels": {
      backgroundColor: "#282828",
      color: "#ebdbb2",
      borderTop: "1px solid #3c3836",
    },
    ".cm-vim-panel": {
      padding: "4px 12px",
      fontFamily: "inherit",
      fontSize: "16px",
      color: "#b8bb26",
    },
    ".cm-vim-panel input": {
      color: "#ebdbb2",
      backgroundColor: "transparent",
      border: "none",
      outline: "none",
      fontFamily: "inherit",
      fontSize: "16px",
      width: "100%",
    },
  },
  { dark: true }
);

const VimEditor = {
  mounted() {
    defineVimCommands();

    this.initial = this.el.dataset.initial || "";
    this.expected = this.el.dataset.expected || "";
    this.taskType = this.el.dataset.taskType || "edit";
    this.targetLine = parseInt(this.el.dataset.targetLine, 10);
    this.targetCol = parseInt(this.el.dataset.targetCol, 10);
    this.keystrokes = 0;
    this.startedAt = Date.now();
    this.currentMode = "normal";
    this.userKeys = "";

    this.view = new EditorView({
      parent: this.el,
      state: this.makeState(this.initial),
    });

    this.attachVimEvents();

    this.onKey = (e) => {
      this.keystrokes++;
      keySound.click();
      this.recordVimKey(e);
      this.scheduleStatsPush();
    };
    this.el.addEventListener("keydown", this.onKey);

    this.tickInterval = setInterval(() => this.pushStats(), 250);

    // ─── External / button triggers ────────────────────────────────────────
    this.handlers = {
      "vim:request-check": () => this.sendCheck(),
      "vim:cmd-check": () => this.sendCheck(),
      "vim:cmd-next": () => this.pushEvent("nav_next"),
      "vim:cmd-prev": () => this.pushEvent("nav_prev"),
      "vim:cmd-reset": () => this.pushEvent("reset"),
      "vim:cmd-hint": () => this.pushEvent("toggle_hint"),
      "vim:cmd-quit": () => this.pushEvent("nav_quit"),
    };
    for (const [name, fn] of Object.entries(this.handlers)) {
      window.addEventListener(name, fn);
    }

    this.handleEvent("vim:reset", ({ text }) => this.resetTo(text));
    this.handleEvent("vim:result", ({ success }) => {
      if (success) keySound.success();
      else keySound.error();
    });

    setTimeout(() => this.view.focus(), 80);
    this.pushStats();
  },

  destroyed() {
    if (this.tickInterval) clearInterval(this.tickInterval);
    if (this.view) this.view.destroy();
    if (this.onKey) this.el.removeEventListener("keydown", this.onKey);
    if (this.handlers) {
      for (const [name, fn] of Object.entries(this.handlers)) {
        window.removeEventListener(name, fn);
      }
    }
  },

  attachVimEvents() {
    const cm = this.view.cm;
    if (!cm) return;
    cm.on("vim-mode-change", ({ mode, subMode }) => {
      this.currentMode = subMode ? `${mode}-${subMode}` : mode;
      this.pushStats();
    });
  },

  scheduleStatsPush() {
    if (this._scheduled) return;
    this._scheduled = true;
    requestAnimationFrame(() => {
      this._scheduled = false;
      this.pushStats();
    });
  },

  computeProgress(text) {
    let i = 0;
    const min = Math.min(text.length, this.expected.length);
    while (i < min && text[i] === this.expected[i]) i++;
    const prefixPct =
      this.expected.length === 0 ? 100 : (i / this.expected.length) * 100;
    const matched = text === this.expected;
    return {
      matched,
      prefix_chars: i,
      expected_len: this.expected.length,
      current_len: text.length,
      progress_pct: matched ? 100 : Math.round(prefixPct),
    };
  },

  pushStats() {
    const text = this.view.state.doc.toString();
    const elapsed = Date.now() - this.startedAt;
    const progress = this.computeProgress(text);
    const { line, col } = this.cursorPos();
    this.pushEvent("vim:stats", {
      mode: this.currentMode,
      keystrokes: this.keystrokes,
      elapsed_ms: elapsed,
      line,
      col,
      user_keys: this.userKeys,
      ...progress,
    });
  },

  cursorPos() {
    try {
      const sel = this.view.state.selection.main;
      const lineObj = this.view.state.doc.lineAt(sel.head);
      return { line: lineObj.number, col: sel.head - lineObj.from };
    } catch (_e) {
      return { line: 1, col: 0 };
    }
  },

  // Record a normal/visual-mode keystroke into the user_keys string for
  // similarity scoring on motion lessons. Skip when in insert mode and
  // skip modifier-only keypresses.
  recordVimKey(e) {
    const cm = this.view.cm;
    const insert =
      cm && cm.state && cm.state.vim && cm.state.vim.insertMode;
    if (insert) return;

    const k = e.key;
    if (!k || k === "Shift" || k === "Control" || k === "Alt" || k === "Meta") return;

    let token;
    if (k === "Escape") token = "<esc>";
    else if (k === "Enter") token = "<cr>";
    else if (k === "Backspace") token = "<bs>";
    else if (k === "Tab") token = "<tab>";
    else if (k === " ") token = "<space>";
    else if (k.length === 1) {
      // Ctrl-modifier shortcuts (e.g. Ctrl-A → "<c-a>")
      if (e.ctrlKey) token = `<c-${k.toLowerCase()}>`;
      else token = k;
    } else {
      // Arrow keys, F-keys, etc.
      token = `<${k.toLowerCase()}>`;
    }

    // Cap recorded length to avoid runaway strings.
    if (this.userKeys.length < 64) this.userKeys += token;
  },

  makeState(text) {
    return EditorState.create({
      doc: text,
      extensions: [
        vim(),
        lineNumbers(),
        highlightActiveLine(),
        highlightActiveLineGutter(),
        EditorView.lineWrapping,
        syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
        vimTheme,
        keymap.of([
          {
            key: "Enter",
            run: (view) => {
              const cm = view.cm;
              if (cm && cm.state && cm.state.vim && !cm.state.vim.insertMode) {
                this.sendCheck();
                return true;
              }
              return false;
            },
          },
        ]),
        EditorView.updateListener.of((u) => {
          if (u.docChanged || u.selectionSet) this.scheduleStatsPush();
        }),
      ],
    });
  },

  resetTo(text) {
    this.keystrokes = 0;
    this.startedAt = Date.now();
    this.currentMode = "normal";
    this.userKeys = "";
    this.view.setState(this.makeState(text));
    this.attachVimEvents();
    setTimeout(() => this.view.focus(), 30);
    this.pushStats();
  },

  sendCheck() {
    const text = this.view.state.doc.toString();
    const timeMs = Date.now() - this.startedAt;
    this.pushEvent("check", {
      text,
      keystrokes: this.keystrokes,
      time_ms: timeMs,
    });
  },
};

export default VimEditor;
