defmodule TypingVimWeb.VimLessonLive do
  use TypingVimWeb, :live_view

  alias TypingVim.Vim
  alias TypingVimWeb.Presence

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    lesson = Vim.get_lesson_by_slug!(slug)

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), Presence.topic(), socket.assigns.guest_id, %{
          page: "vim_lesson",
          slug: slug,
          joined_at: System.system_time(:second)
        })

      Phoenix.PubSub.subscribe(TypingVim.PubSub, Presence.topic())
    end

    next = Vim.next_lesson(lesson)
    prev = Vim.prev_lesson(lesson)

    {:ok,
     socket
     |> assign(:page_title, "#{lesson.title} · TypingVim")
     |> assign(:active, :vim)
     |> assign(:online_count, Presence.online_count())
     |> assign(:lesson, lesson)
     |> assign(:next_lesson, next)
     |> assign(:prev_lesson, prev)
     |> assign(:hint_open, false)
     |> assign(:result, nil)
     |> assign(:live_mode, "normal")
     |> assign(:live_keystrokes, 0)
     |> assign(:live_elapsed_ms, 0)
     |> assign(:live_progress, 0)
     |> assign(:live_matched, false)
     |> assign(:live_current_len, 0)
     |> assign(:live_expected_len, String.length(lesson.expected_text))
     |> assign(:live_line, 1)
     |> assign(:live_col, 0)
     |> assign(:user_keys, "")
     |> assign(:key_similarity, 0)}
  end

  @impl true
  def handle_event("toggle_hint", _, socket) do
    {:noreply, assign(socket, :hint_open, !socket.assigns.hint_open)}
  end

  @impl true
  def handle_event("vim:stats", params, socket) do
    matched = Map.get(params, "matched", false)
    lesson = socket.assigns.lesson
    line = to_int(Map.get(params, "line", 1))
    col = to_int(Map.get(params, "col", 0))
    user_keys = Map.get(params, "user_keys", "") |> to_string()

    motion_solved? =
      lesson.task_type == "motion" and Vim.check_motion(lesson, line, col)

    similarity =
      if lesson.task_type == "motion" do
        Vim.key_similarity(lesson.expected_keys || lesson.primary_keys, user_keys)
      else
        socket.assigns.key_similarity
      end

    socket =
      socket
      |> assign(:live_mode, Map.get(params, "mode", "normal"))
      |> assign(:live_keystrokes, to_int(Map.get(params, "keystrokes", 0)))
      |> assign(:live_elapsed_ms, to_int(Map.get(params, "elapsed_ms", 0)))
      |> assign(:live_progress, to_int(Map.get(params, "progress_pct", 0)))
      |> assign(:live_matched, matched or motion_solved?)
      |> assign(:live_current_len, to_int(Map.get(params, "current_len", 0)))
      |> assign(:live_line, line)
      |> assign(:live_col, col)
      |> assign(:user_keys, user_keys)
      |> assign(:key_similarity, similarity)

    solved? = (lesson.task_type == "edit" and matched) or motion_solved?

    socket =
      if solved? and socket.assigns.result != :ok do
        {:ok, _} =
          Vim.record_attempt(%{
            guest_id: socket.assigns.guest_id,
            lesson_id: lesson.id,
            success: true,
            keystroke_count: socket.assigns.live_keystrokes,
            time_ms: socket.assigns.live_elapsed_ms
          })

        socket
        |> assign(:result, :ok)
        |> push_event("vim:result", %{success: true})
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("check", %{"text" => text} = params, socket) do
    lesson = socket.assigns.lesson
    success = Vim.check_solution(lesson, text)
    keystrokes = Map.get(params, "keystrokes", 0)
    time_ms = Map.get(params, "time_ms", 0)

    {:ok, _} =
      Vim.record_attempt(%{
        guest_id: socket.assigns.guest_id,
        lesson_id: lesson.id,
        success: success,
        keystroke_count: to_int(keystrokes),
        time_ms: to_int(time_ms)
      })

    {:noreply,
     socket
     |> assign(:result, if(success, do: :ok, else: :fail))
     |> push_event("vim:result", %{success: success})}
  end

  @impl true
  def handle_event("reset", _, socket) do
    {:noreply,
     socket
     |> assign(:result, nil)
     |> assign(:live_mode, "normal")
     |> assign(:live_keystrokes, 0)
     |> assign(:live_elapsed_ms, 0)
     |> assign(:live_progress, 0)
     |> assign(:live_matched, false)
     |> assign(:user_keys, "")
     |> assign(:key_similarity, 0)
     |> push_event("vim:reset", %{text: socket.assigns.lesson.initial_text})}
  end

  @impl true
  def handle_event("nav_next", _, socket) do
    case socket.assigns.next_lesson do
      nil -> {:noreply, push_navigate(socket, to: ~p"/vim")}
      next -> {:noreply, push_navigate(socket, to: ~p"/vim/#{next.slug}")}
    end
  end

  @impl true
  def handle_event("nav_prev", _, socket) do
    case socket.assigns.prev_lesson do
      nil -> {:noreply, push_navigate(socket, to: ~p"/vim")}
      prev -> {:noreply, push_navigate(socket, to: ~p"/vim/#{prev.slug}")}
    end
  end

  @impl true
  def handle_event("nav_quit", _, socket) do
    {:noreply, push_navigate(socket, to: ~p"/vim")}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_count, Presence.online_count())}
  end

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v) when is_binary(v), do: String.to_integer(v)
  defp to_int(v) when is_float(v), do: trunc(v)
  defp to_int(_), do: 0

  defp format_mode(mode) do
    base =
      mode
      |> to_string()
      |> String.split("-", parts: 2)
      |> List.first()
      |> String.upcase()

    "-- #{base} --"
  end

  defp mode_class("insert" <> _), do: "text-[#fb4934]"
  defp mode_class("visual" <> _), do: "text-[#d3869b]"
  defp mode_class("replace" <> _), do: "text-[#fe8019]"
  defp mode_class(_), do: "text-[#b8bb26]"

  defp format_time(ms) do
    total_seconds = div(ms, 1000)
    mins = div(total_seconds, 60)
    secs = rem(total_seconds, 60)
    :io_lib.format("~2..0B:~2..0B", [mins, secs]) |> IO.iodata_to_binary()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} online_count={@online_count} active={@active}>
      <section class="flex-1 px-4 py-6 sm:py-10">
        <div class="max-w-5xl mx-auto space-y-6">
          <!-- Mobile blocker -->
          <div class="md:hidden rounded-lg bg-warning/10 border border-warning/30 text-warning p-6 text-center font-mono text-sm">
            keyboard required.<br /> please open on a desktop.
          </div>

          <div class="hidden md:block space-y-5">
            <!-- Breadcrumb + title -->
            <header class="space-y-3">
              <.link
                navigate={~p"/vim"}
                class="text-xs text-base-content/50 hover:text-base-content font-mono"
              >
                ← all lessons (:q)
              </.link>
              <div class="flex items-baseline justify-between gap-4">
                <h1 class="text-2xl sm:text-3xl font-bold font-mono">
                  <span class="text-[#83a598]">:</span>{@lesson.title}
                </h1>
                <span class="text-xs text-base-content/50 font-mono uppercase tracking-wider">
                  [{@lesson.category}] · diff {@lesson.difficulty}
                </span>
              </div>
              <%= if @lesson.description do %>
                <p class="text-base-content/70 leading-relaxed text-sm">
                  {@lesson.description}
                </p>
              <% end %>
            </header>
            
    <!-- Target output preview (terminal-style) -->
            <div class="rounded-md overflow-hidden border border-[#3c3836] bg-[#1d2021] font-mono text-base shadow-lg">
              <div class="flex items-center gap-2 px-3 py-1.5 bg-[#282828] border-b border-[#3c3836]">
                <span class="w-3 h-3 rounded-full bg-[#fb4934]"></span>
                <span class="w-3 h-3 rounded-full bg-[#fabd2f]"></span>
                <span class="w-3 h-3 rounded-full bg-[#b8bb26]"></span>
                <span class="ml-3 text-xs text-[#928374]">target.txt — read-only</span>
              </div>
              <pre
                class="px-4 py-3 text-[#b8bb26] whitespace-pre-wrap break-words text-[15px] leading-relaxed"
                phx-no-curly-interpolation
              >{@lesson.expected_text}</pre>
            </div>
            
    <!-- Editor window (terminal frame) -->
            <div class="rounded-md overflow-hidden border border-[#3c3836] bg-[#1d2021] shadow-xl">
              <div class="flex items-center gap-2 px-3 py-1.5 bg-[#282828] border-b border-[#3c3836] font-mono text-xs">
                <span class="w-3 h-3 rounded-full bg-[#fb4934]"></span>
                <span class="w-3 h-3 rounded-full bg-[#fabd2f]"></span>
                <span class="w-3 h-3 rounded-full bg-[#b8bb26]"></span>
                <span class="ml-3 text-[#928374]">
                  ~/lesson/{@lesson.slug}.txt — VIM
                </span>
                <span class="ml-auto text-[#928374]">utf-8 · suggested: {@lesson.primary_keys}</span>
              </div>

              <div
                id="vim-editor"
                phx-hook="VimEditor"
                phx-update="ignore"
                data-initial={@lesson.initial_text}
                data-expected={@lesson.expected_text}
                data-slug={@lesson.slug}
                data-task-type={@lesson.task_type}
                data-target-line={@lesson.target_line}
                data-target-col={@lesson.target_col}
              >
              </div>
              
    <!-- Vim status line (live) -->
              <div class="flex items-stretch font-mono text-xs bg-[#282828] border-t border-[#3c3836]">
                <div class={["px-3 py-1.5 font-semibold", mode_class(@live_mode)]}>
                  {format_mode(@live_mode)}
                </div>
                <div class="px-3 py-1.5 text-[#928374] border-l border-[#3c3836]">
                  {@lesson.slug}.txt
                </div>
                <div class="ml-auto flex items-stretch text-[#a89984]">
                  <div class="px-3 py-1.5 border-l border-[#3c3836]">
                    keys <span class="text-[#fabd2f]">{@live_keystrokes}</span>
                  </div>
                  <div class="px-3 py-1.5 border-l border-[#3c3836]">
                    time <span class="text-[#fabd2f]">{format_time(@live_elapsed_ms)}</span>
                  </div>
                  <div class="px-3 py-1.5 border-l border-[#3c3836]">
                    {@live_current_len}/{@live_expected_len} ch
                  </div>
                  <div class="px-3 py-1.5 border-l border-[#3c3836]">
                    <%= if @lesson.task_type == "motion" do %>
                      <span class="text-[#928374]">cur</span>
                      <span class="text-[#fabd2f]">{@live_line}:{@live_col}</span>
                      <%= if @lesson.target_line do %>
                        <span class="text-[#928374]">→</span>
                        <span class="text-[#83a598]">
                          {@lesson.target_line}{if @lesson.target_col, do: ":#{@lesson.target_col}"}
                        </span>
                      <% end %>
                    <% else %>
                      <span class="text-[#928374]">{@live_line}:{@live_col}</span>
                    <% end %>
                  </div>
                  <div class="px-3 py-1.5 border-l border-[#3c3836] bg-[#1d2021]">
                    <span class={[
                      "font-semibold",
                      @live_matched && "text-[#b8bb26]",
                      !@live_matched && "text-[#fabd2f]"
                    ]}>
                      <%= if @live_matched do %>
                        ✓ 100%
                      <% else %>
                        {@live_progress}%
                      <% end %>
                    </span>
                  </div>
                </div>
              </div>
              
    <!-- Progress bar -->
              <div class="h-1 bg-[#1d2021] relative overflow-hidden">
                <div
                  class={[
                    "absolute inset-y-0 left-0 transition-all duration-150",
                    @live_matched && "bg-[#b8bb26]",
                    !@live_matched && "bg-[#fabd2f]"
                  ]}
                  style={"width: #{@live_progress}%"}
                >
                </div>
              </div>
            </div>
            
    <!-- Key-sequence comparison (motion lessons only) -->
            <%= if @lesson.task_type == "motion" do %>
              <div class="rounded-md border border-[#3c3836] bg-[#1d2021] p-4 font-mono text-sm space-y-2">
                <div class="flex items-center justify-between text-xs uppercase tracking-wider text-[#928374]">
                  <span>your keys vs expected</span>
                  <span class={[
                    "px-2 py-0.5 rounded",
                    @key_similarity >= 100 && "bg-[#b8bb26]/20 text-[#b8bb26]",
                    @key_similarity < 100 && @key_similarity >= 60 &&
                      "bg-[#fabd2f]/20 text-[#fabd2f]",
                    @key_similarity < 60 && "bg-[#fb4934]/20 text-[#fb4934]"
                  ]}>
                    {@key_similarity}% similar
                  </span>
                </div>
                <div class="grid grid-cols-[80px_1fr] gap-x-3 gap-y-1.5 items-baseline">
                  <span class="text-[#928374] text-xs">expected</span>
                  <code class="text-[#83a598] bg-[#282828] px-2 py-1 rounded">
                    {@lesson.expected_keys || @lesson.primary_keys || "—"}
                  </code>
                  <span class="text-[#928374] text-xs">you typed</span>
                  <code class={[
                    "px-2 py-1 rounded bg-[#282828] min-h-[28px] break-all",
                    @user_keys == "" && "text-[#665c54] italic",
                    @user_keys != "" && "text-[#fabd2f]"
                  ]}>
                    {if @user_keys == "", do: "(start typing in normal mode…)", else: @user_keys}
                  </code>
                </div>
              </div>
            <% end %>
            <%= cond do %>
              <% @result == :ok -> %>
                <div class="rounded-md bg-[#b8bb26]/10 border border-[#b8bb26]/40 p-4 font-mono text-sm space-y-1">
                  <div class="text-[#b8bb26] font-semibold">
                    ✓ solved in {format_time(@live_elapsed_ms)} · {@live_keystrokes} keystrokes
                  </div>
                  <div class="text-[#a89984]">
                    <%= if @next_lesson do %>
                      type <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:n</kbd>
                      or <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">gn</kbd>
                      → next: <span class="text-[#83a598]">:{@next_lesson.title}</span>
                    <% else %>
                      that was the last lesson! type
                      <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:q</kbd>
                      to go back
                    <% end %>
                  </div>
                </div>
              <% true -> %>
            <% end %>

            <%= if @hint_open and @lesson.hint do %>
              <div class="rounded-md bg-[#1d2021] border border-[#83a598]/40 p-4 text-sm text-[#83a598] font-mono leading-relaxed">
                <span class="text-[#fabd2f]">hint &gt;</span> {@lesson.hint}
                <div class="mt-2 text-xs text-[#928374]">
                  type <kbd class="px-1 bg-[#3c3836] rounded">:h</kbd> again to hide
                </div>
              </div>
            <% end %>
            
    <!-- Keyboard cheatsheet (always visible — replaces fake buttons) -->
            <div class="rounded-md border border-[#3c3836] bg-[#282828]/40 px-4 py-3 font-mono text-xs text-[#a89984] flex flex-wrap items-center gap-x-5 gap-y-1.5">
              <span class="text-[#928374] uppercase tracking-wider">
                no mouse needed →
              </span>
              <span>
                <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:w</kbd>
                <span class="ml-1 text-[#928374]">check</span>
              </span>
              <span>
                <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:n</kbd>
                / <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">gn</kbd>
                <span class="ml-1 text-[#928374]">next</span>
              </span>
              <span>
                <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:p</kbd>
                / <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">gp</kbd>
                <span class="ml-1 text-[#928374]">prev</span>
              </span>
              <span>
                <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:r</kbd>
                / <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">gr</kbd>
                <span class="ml-1 text-[#928374]">reset</span>
              </span>
              <span>
                <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:h</kbd>
                / <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">gh</kbd>
                <span class="ml-1 text-[#928374]">hint</span>
              </span>
              <span>
                <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:q</kbd>
                / <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">gq</kbd>
                <span class="ml-1 text-[#928374]">list</span>
              </span>
              <span>
                <kbd class="px-1.5 py-0.5 bg-[#3c3836] rounded text-[#fabd2f]">:wq</kbd>
                <span class="ml-1 text-[#928374]">check + next</span>
              </span>
            </div>

            <%= if @result == :fail do %>
              <div class="rounded-md bg-[#fb4934]/10 border border-[#fb4934]/40 p-3 text-sm text-[#fb4934] font-mono">
                ✗ not matching yet — watch the progress bar above
              </div>
            <% end %>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
