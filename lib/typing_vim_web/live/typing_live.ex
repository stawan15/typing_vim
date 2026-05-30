defmodule TypingVimWeb.TypingLive do
  use TypingVimWeb, :live_view

  alias TypingVim.Typing
  alias TypingVimWeb.Presence

  @default_mode "time"
  @default_duration 30

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), Presence.topic(), socket.assigns.guest_id, %{
          page: "type",
          joined_at: System.system_time(:second)
        })

      Phoenix.PubSub.subscribe(TypingVim.PubSub, Presence.topic())
    end

    {:ok,
     socket
     |> assign(:page_title, "Type · TypingVim")
     |> assign(:active, :type)
     |> assign(:online_count, Presence.online_count())
     |> assign(:mode, @default_mode)
     |> assign(:duration, @default_duration)
     |> assign(:state, :idle)
     |> assign(:text, Typing.generate_test(@default_mode, @default_duration))
     |> assign(:result, nil)
     |> assign(:saved, false)
     |> assign(:display_name, "")
     |> assign(:personal_best, nil)}
  end

  @impl true
  def handle_event("set_mode", %{"mode" => mode}, socket) when mode in ["time", "words"] do
    {:noreply, reset(socket, mode: mode)}
  end

  @impl true
  def handle_event("set_duration", %{"duration" => d}, socket) do
    duration = String.to_integer(d)
    {:noreply, reset(socket, duration: duration)}
  end

  @impl true
  def handle_event("new_test", _, socket) do
    {:noreply, reset(socket)}
  end

  @impl true
  def handle_event("running", _, socket) do
    {:noreply, assign(socket, :state, :running)}
  end

  @impl true
  def handle_event(
        "finish",
        %{
          "correct_chars" => correct,
          "incorrect_chars" => incorrect,
          "duration_sec" => duration,
          "word_count" => word_count
        },
        socket
      ) do
    correct = to_int(correct)
    incorrect = to_int(incorrect)
    duration = to_int(duration)
    word_count = to_int(word_count)
    minutes = max(duration / 60, 1 / 60)
    raw_wpm = Float.round(correct / 5 / minutes, 1)
    total = correct + incorrect

    accuracy =
      if total > 0,
        do: Float.round(correct / total * 100, 1),
        else: 0.0

    wpm = Float.round(raw_wpm * accuracy / 100, 1)

    result = %{
      mode: socket.assigns.mode,
      duration_sec: duration,
      word_count: word_count,
      wpm: wpm,
      raw_wpm: raw_wpm,
      accuracy: accuracy,
      correct_chars: correct,
      incorrect_chars: incorrect
    }

    pb = Typing.recent_personal_best(socket.assigns.guest_id, socket.assigns.mode, duration)

    {:noreply,
     socket
     |> assign(:state, :finished)
     |> assign(:result, result)
     |> assign(:personal_best, pb)
     |> assign(:saved, false)}
  end

  @impl true
  def handle_event("save_result", %{"display_name" => name}, socket) do
    result = socket.assigns.result || %{}

    attrs =
      result
      |> Map.put(:guest_id, socket.assigns.guest_id)
      |> Map.put(:display_name, name)

    case Typing.create_result(attrs) do
      {:ok, _r} ->
        {:noreply, socket |> assign(:saved, true) |> assign(:display_name, name)}

      {:error, _cs} ->
        {:noreply, put_flash(socket, :error, "Could not save result. Try a shorter name.")}
    end
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_count, Presence.online_count())}
  end

  defp reset(socket, opts \\ []) do
    mode = Keyword.get(opts, :mode, socket.assigns.mode)
    duration = Keyword.get(opts, :duration, socket.assigns.duration)

    socket
    |> assign(:mode, mode)
    |> assign(:duration, duration)
    |> assign(:state, :idle)
    |> assign(:text, Typing.generate_test(mode, duration))
    |> assign(:result, nil)
    |> assign(:saved, false)
    |> push_event("typing:reset", %{})
  end

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v) when is_binary(v), do: String.to_integer(v)
  defp to_int(v) when is_float(v), do: trunc(v)

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} online_count={@online_count} active={@active}>
      <section class="flex-1 flex flex-col items-center justify-start px-4 pt-8 pb-12">
        <div class="w-full max-w-4xl space-y-6">
          <!-- Mode selector -->
          <div class="flex flex-wrap items-center justify-center gap-3 text-sm font-mono">
            <div class="flex items-center gap-1 px-3 py-1.5 rounded-full bg-base-200/60 border border-base-300/60">
              <button
                :for={m <- ["time", "words"]}
                phx-click="set_mode"
                phx-value-mode={m}
                class={[
                  "px-3 py-1 rounded-full transition-colors",
                  @mode == m && "text-primary",
                  @mode != m && "text-base-content/40 hover:text-base-content"
                ]}
              >
                {m}
              </button>
            </div>

            <div class="flex items-center gap-1 px-3 py-1.5 rounded-full bg-base-200/60 border border-base-300/60">
              <button
                :for={d <- [15, 30, 60, 120]}
                phx-click="set_duration"
                phx-value-duration={d}
                class={[
                  "px-3 py-1 rounded-full transition-colors tabular-nums",
                  @duration == d && "text-primary",
                  @duration != d && "text-base-content/40 hover:text-base-content"
                ]}
              >
                {d}
              </button>
            </div>
          </div>
          
    <!-- HUD: timer + wpm live -->
          <div class="flex items-center justify-center gap-8 font-mono">
            <div class="text-center">
              <div class="text-xs text-base-content/40 uppercase tracking-wider">time</div>
              <div id="hud-time" class="text-3xl text-primary tabular-nums">{@duration}</div>
            </div>
            <div class="text-center">
              <div class="text-xs text-base-content/40 uppercase tracking-wider">wpm</div>
              <div id="hud-wpm" class="text-3xl text-accent tabular-nums">0</div>
            </div>
            <div class="text-center">
              <div class="text-xs text-base-content/40 uppercase tracking-wider">acc</div>
              <div id="hud-acc" class="text-3xl text-base-content/80 tabular-nums">100%</div>
            </div>
          </div>
          
    <!-- Typing area -->
          <%= if @state in [:idle, :running] do %>
            <div
              id="typing-engine"
              phx-hook="TypingEngine"
              phx-update="ignore"
              data-text={@text}
              data-duration={@duration}
              data-mode={@mode}
              class="relative"
            >
              <div
                class="select-none cursor-text rounded-lg bg-base-200/30 border border-base-300/40 p-6 sm:p-8 font-mono text-2xl sm:text-3xl leading-relaxed tracking-wide focus:outline-none focus:border-primary/60 transition-colors min-h-[220px]"
                tabindex="0"
                data-typing-target="container"
              >
                <div data-typing-target="words" class="text-base-content/30"></div>
              </div>
              <div class="mt-3 text-center text-xs text-base-content/30 font-mono">
                click the box and start typing · esc to reset
              </div>
            </div>
          <% end %>
          
    <!-- Result screen -->
          <%= if @state == :finished and @result do %>
            <div class="rounded-lg bg-base-200/30 border border-base-300/40 p-8 space-y-6">
              <div class="text-center space-y-1">
                <h2 class="text-sm uppercase tracking-widest text-base-content/40">test complete</h2>
              </div>

              <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 text-center font-mono">
                <.stat label="wpm" value={@result.wpm} accent="text-primary text-5xl" />
                <.stat label="raw" value={@result.raw_wpm} accent="text-accent text-3xl" />
                <.stat label="acc" value={"#{@result.accuracy}%"} accent="text-success text-3xl" />
                <.stat
                  label="chars"
                  value={"#{@result.correct_chars}/#{@result.incorrect_chars}"}
                  accent="text-base-content/80 text-2xl"
                />
              </div>

              <%= if @personal_best do %>
                <div class="text-center text-xs text-base-content/40 font-mono">
                  personal best for this mode:
                  <span class="text-base-content/70">{@personal_best.wpm} wpm</span>
                  <%= if @result.wpm > @personal_best.wpm do %>
                    <span class="text-success ml-2">— new pb! 🎉</span>
                  <% end %>
                </div>
              <% end %>

              <div class="border-t border-base-300/40 pt-6 space-y-3">
                <%= if @saved do %>
                  <p class="text-center text-success font-mono text-sm">
                    ✓ saved as <span class="font-semibold">{@display_name || "anon"}</span>
                    — check the
                    <.link navigate={~p"/leaderboard"} class="underline">leaderboard</.link>
                  </p>
                <% else %>
                  <form
                    phx-submit="save_result"
                    class="flex flex-col sm:flex-row gap-2 items-stretch sm:items-center justify-center"
                  >
                    <input
                      type="text"
                      name="display_name"
                      maxlength="24"
                      placeholder="display name (optional)"
                      class="flex-1 max-w-xs px-3 py-2 rounded-md bg-base-100 border border-base-300 focus:outline-none focus:border-primary text-sm font-mono"
                    />
                    <button
                      type="submit"
                      class="px-4 py-2 rounded-md bg-primary text-primary-content font-semibold text-sm hover:bg-primary/90"
                    >
                      save to leaderboard
                    </button>
                  </form>
                <% end %>

                <div class="flex justify-center gap-2 pt-2">
                  <button
                    phx-click="new_test"
                    class="px-6 py-2 rounded-md bg-base-300/50 hover:bg-base-300 text-sm font-mono"
                  >
                    new test (tab)
                  </button>
                  <.link
                    navigate={~p"/leaderboard"}
                    class="px-6 py-2 rounded-md bg-base-300/50 hover:bg-base-300 text-sm font-mono"
                  >
                    leaderboard
                  </.link>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </section>
    </Layouts.app>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true
  attr :accent, :string, default: ""

  defp stat(assigns) do
    ~H"""
    <div>
      <div class={["font-bold tabular-nums", @accent]}>{@value}</div>
      <div class="text-xs text-base-content/40 uppercase tracking-wider mt-1">{@label}</div>
    </div>
    """
  end
end
