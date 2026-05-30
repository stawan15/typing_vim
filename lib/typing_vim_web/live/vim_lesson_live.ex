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

    {:ok,
     socket
     |> assign(:page_title, "#{lesson.title} · TypingVim")
     |> assign(:active, :vim)
     |> assign(:online_count, Presence.online_count())
     |> assign(:lesson, lesson)
     |> assign(:next_lesson, next)
     |> assign(:hint_open, false)
     |> assign(:result, nil)}
  end

  @impl true
  def handle_event("toggle_hint", _, socket) do
    {:noreply, assign(socket, :hint_open, !socket.assigns.hint_open)}
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
     |> push_event("vim:reset", %{text: socket.assigns.lesson.initial_text})}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_count, Presence.online_count())}
  end

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v) when is_binary(v), do: String.to_integer(v)
  defp to_int(v) when is_float(v), do: trunc(v)
  defp to_int(_), do: 0

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} online_count={@online_count} active={@active}>
      <section class="flex-1 px-4 py-8 sm:py-12">
        <div class="max-w-3xl mx-auto space-y-6">
          <!-- Mobile blocker -->
          <div class="md:hidden rounded-lg bg-warning/10 border border-warning/30 text-warning p-6 text-center font-mono text-sm">
            ⌨️ vim lessons require a physical keyboard.<br /> please open on desktop.
          </div>

          <div class="hidden md:block space-y-6">
            <header class="space-y-2">
              <.link
                navigate={~p"/vim"}
                class="text-xs text-base-content/40 hover:text-base-content font-mono"
              >
                ← all lessons
              </.link>
              <div class="flex items-baseline justify-between gap-4">
                <h1 class="text-2xl sm:text-3xl font-bold">{@lesson.title}</h1>
                <span class="text-xs text-base-content/40 font-mono uppercase">
                  {@lesson.category}
                </span>
              </div>
              <%= if @lesson.description do %>
                <p class="text-base-content/70 leading-relaxed">{@lesson.description}</p>
              <% end %>
            </header>
            
    <!-- Expected result preview -->
            <div class="text-xs text-base-content/40 font-mono">
              target output:
            </div>
            <pre
              class="text-sm font-mono bg-base-300/30 border border-base-300/60 rounded-md p-3 whitespace-pre-wrap break-words text-success/80"
              phx-no-curly-interpolation
            >{@lesson.expected_text}</pre>
            
    <!-- CodeMirror editor mount point -->
            <div
              id="vim-editor"
              phx-hook="VimEditor"
              phx-update="ignore"
              data-initial={@lesson.initial_text}
              data-slug={@lesson.slug}
              class="rounded-md border border-base-300/60 overflow-hidden focus-within:border-primary/60 transition-colors"
            >
            </div>

            <div class="flex flex-wrap items-center gap-3">
              <button
                phx-click={JS.dispatch("vim:request-check")}
                class="px-4 py-2 rounded-md bg-primary text-primary-content font-semibold text-sm hover:bg-primary/90"
              >
                check (⏎ in normal mode)
              </button>
              <button
                phx-click="reset"
                class="px-4 py-2 rounded-md bg-base-300/50 hover:bg-base-300 text-sm font-mono"
              >
                reset
              </button>
              <button
                phx-click="toggle_hint"
                class="ml-auto px-4 py-2 rounded-md bg-base-200/60 border border-base-300/60 hover:bg-base-300 text-sm font-mono"
              >
                <%= if @hint_open do %>
                  hide hint
                <% else %>
                  show hint
                <% end %>
              </button>
            </div>

            <%= if @hint_open and @lesson.hint do %>
              <div class="rounded-md bg-info/5 border border-info/30 p-4 text-sm text-info-content/80 font-mono leading-relaxed">
                💡 {@lesson.hint}
              </div>
            <% end %>

            <%= cond do %>
              <% @result == :ok -> %>
                <div class="rounded-md bg-success/10 border border-success/30 p-4 flex items-center justify-between gap-4 font-mono">
                  <div class="text-success">✓ correct! lesson solved.</div>
                  <%= if @next_lesson do %>
                    <.link
                      navigate={~p"/vim/#{@next_lesson.slug}"}
                      class="px-4 py-1.5 rounded bg-success/20 hover:bg-success/30 text-success text-sm"
                    >
                      next → {@next_lesson.title}
                    </.link>
                  <% else %>
                    <.link navigate={~p"/vim"} class="text-sm text-success/80 underline">
                      back to lessons
                    </.link>
                  <% end %>
                </div>
              <% @result == :fail -> %>
                <div class="rounded-md bg-error/10 border border-error/30 p-4 text-sm text-error font-mono">
                  ✗ not quite. compare your output with the target above, then try again or check the hint.
                </div>
              <% true -> %>
            <% end %>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
