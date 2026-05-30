import { keySound } from "./sound";

// TypingEngine — drives the MonkeyType-style typing test entirely in the browser
// then pushes the final aggregated result to the LiveView when finished.
const TypingEngine = {
  mounted() {
    this.container = this.el.querySelector('[data-typing-target="container"]');
    this.wordsEl = this.el.querySelector('[data-typing-target="words"]');
    this.hudTime = document.getElementById("hud-time");
    this.hudWpm = document.getElementById("hud-wpm");
    this.hudAcc = document.getElementById("hud-acc");

    this.boundKey = (e) => this.onKey(e);
    this.boundGlobalKey = (e) => this.onGlobalKey(e);
    this.container.addEventListener("keydown", this.boundKey);
    window.addEventListener("keydown", this.boundGlobalKey);

    // refocus on click
    this.el.addEventListener("click", () => this.container.focus());

    // reset event from server
    this.handleEvent("typing:reset", () => this.reset());

    this.reset();
    setTimeout(() => this.container.focus(), 50);
  },

  destroyed() {
    if (this.container) this.container.removeEventListener("keydown", this.boundKey);
    window.removeEventListener("keydown", this.boundGlobalKey);
    if (this.tickTimer) clearInterval(this.tickTimer);
    if (this.endTimer) clearTimeout(this.endTimer);
  },

  reset() {
    if (this.tickTimer) clearInterval(this.tickTimer);
    if (this.endTimer) clearTimeout(this.endTimer);
    this.text = this.el.dataset.text || "";
    this.duration = parseInt(this.el.dataset.duration, 10) || 30;
    this.mode = this.el.dataset.mode || "time";
    this.typed = "";
    this.correctChars = 0;
    this.incorrectChars = 0;
    this.started = false;
    this.startedAt = null;
    this.finished = false;
    this.updateHud(this.duration, 0, 100);
    this.renderWords();
  },

  start() {
    if (this.started) return;
    this.started = true;
    this.startedAt = Date.now();

    if (this.mode === "time") {
      this.endTimer = setTimeout(() => this.finish(), this.duration * 1000);
      this.tickTimer = setInterval(() => this.tick(), 250);
    } else {
      this.tickTimer = setInterval(() => this.tick(), 250);
    }

    this.pushEvent("running", {});
  },

  tick() {
    if (!this.started || this.finished) return;
    const elapsed = (Date.now() - this.startedAt) / 1000;
    const remaining = Math.max(0, this.duration - elapsed);
    const minutes = Math.max(elapsed / 60, 1 / 60);
    const rawWpm = Math.round(this.correctChars / 5 / minutes);
    const total = this.correctChars + this.incorrectChars;
    const acc = total > 0 ? Math.round((this.correctChars / total) * 100) : 100;

    if (this.mode === "time") {
      this.updateHud(Math.ceil(remaining), rawWpm, acc);
    } else {
      this.updateHud(Math.floor(elapsed), rawWpm, acc);
    }
  },

  updateHud(time, wpm, acc) {
    if (this.hudTime) this.hudTime.textContent = time;
    if (this.hudWpm) this.hudWpm.textContent = wpm;
    if (this.hudAcc) this.hudAcc.textContent = acc + "%";
  },

  onGlobalKey(e) {
    // Tab to restart test from anywhere
    if (e.key === "Tab") {
      e.preventDefault();
      this.pushEvent("new_test", {});
      return;
    }
    if (e.key === "Escape") {
      e.preventDefault();
      this.reset();
    }
  },

  onKey(e) {
    if (this.finished) return;

    // ignore modifier-only keys
    if (e.ctrlKey || e.metaKey || e.altKey) return;

    const k = e.key;

    if (k === "Backspace") {
      e.preventDefault();
      if (this.typed.length > 0) {
        const removed = this.typed[this.typed.length - 1];
        const expected = this.text[this.typed.length - 1];
        // un-count the removed char
        if (removed === expected) {
          this.correctChars = Math.max(0, this.correctChars - 1);
        } else {
          this.incorrectChars = Math.max(0, this.incorrectChars - 1);
        }
        this.typed = this.typed.slice(0, -1);
        this.renderWords();
      }
      return;
    }

    if (k.length !== 1) return; // ignore arrows, function keys, etc.
    e.preventDefault();

    if (!this.started) this.start();

    const expected = this.text[this.typed.length];
    this.typed += k;

    if (k === expected) {
      this.correctChars++;
      keySound.click();
    } else {
      this.incorrectChars++;
      keySound.error();
    }

    // Words mode: detect end when typed reaches text length
    if (this.typed.length >= this.text.length) {
      this.finish();
      return;
    }

    this.renderWords();
  },

  renderWords() {
    // Build span per char with appropriate color class
    const text = this.text;
    const typed = this.typed;
    const frag = document.createDocumentFragment();

    for (let i = 0; i < text.length; i++) {
      const span = document.createElement("span");
      span.textContent = text[i];
      if (i < typed.length) {
        if (typed[i] === text[i]) {
          span.className = "text-base-content";
        } else {
          span.className = "text-error underline decoration-error/60";
          // visualize wrong char by showing typed char if expected was space
          if (text[i] === " " && typed[i] !== " ") {
            span.textContent = typed[i];
          }
        }
      } else if (i === typed.length) {
        span.className = "text-base-content/30 border-l-2 border-primary animate-pulse";
      } else {
        span.className = "text-base-content/30";
      }
      frag.appendChild(span);
    }

    this.wordsEl.innerHTML = "";
    this.wordsEl.appendChild(frag);
  },

  finish() {
    if (this.finished) return;
    this.finished = true;
    if (this.tickTimer) clearInterval(this.tickTimer);
    if (this.endTimer) clearTimeout(this.endTimer);

    const elapsedSec = Math.max(1, Math.round((Date.now() - this.startedAt) / 1000));
    const usedDuration = this.mode === "time" ? this.duration : elapsedSec;
    const wordCount = this.text.split(/\s+/).filter(Boolean).length;

    keySound.success();

    this.pushEvent("finish", {
      correct_chars: this.correctChars,
      incorrect_chars: this.incorrectChars,
      duration_sec: usedDuration,
      word_count: wordCount,
    });
  },
};

export default TypingEngine;
