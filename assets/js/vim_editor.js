import { EditorView, basicSetup } from "codemirror";
import { EditorState } from "@codemirror/state";
import { vim } from "@replit/codemirror-vim";
import { oneDark } from "@codemirror/theme-one-dark";
import { keymap } from "@codemirror/view";
import { keySound } from "./sound";

const VimEditor = {
  mounted() {
    this.initial = this.el.dataset.initial || "";
    this.keystrokes = 0;
    this.startedAt = Date.now();

    this.view = new EditorView({
      parent: this.el,
      state: this.makeState(this.initial),
    });

    // Count keystrokes for stats
    this.onKey = (e) => {
      this.keystrokes++;
      keySound.click();
    };
    this.el.addEventListener("keydown", this.onKey);

    // Listen for "check" command from outside (button)
    this.checkHandler = () => this.sendCheck();
    window.addEventListener("vim:request-check", this.checkHandler);

    // Handle server events
    this.handleEvent("vim:reset", ({ text }) => this.resetTo(text));
    this.handleEvent("vim:result", ({ success }) => {
      if (success) keySound.success();
      else keySound.error();
    });

    setTimeout(() => this.view.focus(), 80);
  },

  destroyed() {
    if (this.view) this.view.destroy();
    if (this.onKey) this.el.removeEventListener("keydown", this.onKey);
    if (this.checkHandler) window.removeEventListener("vim:request-check", this.checkHandler);
  },

  makeState(text) {
    return EditorState.create({
      doc: text,
      extensions: [
        vim(),
        basicSetup,
        oneDark,
        EditorView.theme({
          "&": { fontSize: "16px" },
          ".cm-content": { fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace", padding: "12px 0" },
          ".cm-editor": { minHeight: "220px" },
        }),
        keymap.of([
          {
            key: "Enter",
            run: (view) => {
              // In vim normal mode, hitting Enter triggers a check.
              // We detect via the vim state: cm-vim-panel or by checking mode.
              const cm = view.cm; // codemirror-vim exposes legacy cm
              if (cm && cm.state && cm.state.vim && !cm.state.vim.insertMode) {
                this.sendCheck();
                return true;
              }
              return false;
            },
          },
        ]),
      ],
    });
  },

  resetTo(text) {
    this.keystrokes = 0;
    this.startedAt = Date.now();
    this.view.setState(this.makeState(text));
    setTimeout(() => this.view.focus(), 30);
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
