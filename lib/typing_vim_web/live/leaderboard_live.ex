defmodule TypingVimWeb.LeaderboardLive do
  use TypingVimWeb, :live_view

  alias TypingVim.Typing
  alias TypingVimWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), Presence.topic(), socket.assigns.guest_id, %{
          page: "leaderboard",
          joined_at: System.system_time(:second)
        })

      Phoenix.PubSub.subscribe(TypingVim.PubSub, Presence.topic())
    end

    mode = "time"
    duration = 30

    {:ok,
     socket
     |> assign(:page_title, "Leaderboard · TypingVim")
     |> assign(:active, :leaderboard)
     |> assign(:online_count, Presence.online_count())
     |> assign(:mode, mode)
     |> assign(:duration, duration)
     |> load_board(mode, duration)}
  end

  @impl true
  def handle_event("filter", %{"mode" => mode, "duration" => d}, socket) do
    duration = String.to_integer(d)

    {:noreply,
     socket |> assign(:mode, mode) |> assign(:duration, duration) |> load_board(mode, duration)}
  end

  @impl true
  def handle_event("set_duration", %{"duration" => d}, socket) do
    duration = String.to_integer(d)
    {:noreply, socket |> assign(:duration, duration) |> load_board(socket.assigns.mode, duration)}
  end

  @impl true
  def handle_event("set_mode", %{"mode" => mode}, socket) do
    {:noreply, socket |> assign(:mode, mode) |> load_board(mode, socket.assigns.duration)}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_count, Presence.online_count())}
  end

  defp load_board(socket, mode, duration) do
    assign(socket, :results, Typing.leaderboard(mode, duration, 25))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} online_count={@online_count} active={@active}>
      <section class="flex-1 px-4 py-8 sm:py-12">
        <div class="max-w-3xl mx-auto space-y-6">
          <header class="text-center space-y-1">
            <h1 class="text-3xl font-bold tracking-tight">leaderboard</h1>
            <p class="text-sm text-base-content/50 font-mono">top 25 · all time</p>
          </header>

          <div class="flex flex-wrap justify-center gap-3 text-sm font-mono">
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

          <%= if @results == [] do %>
            <div class="rounded-lg bg-base-200/30 border border-base-300/40 p-12 text-center text-base-content/40 font-mono">
              no results yet for {@mode} · {@duration}s — be the first!
              <div class="mt-4">
                <.link navigate={~p"/type"} class="text-primary underline text-sm">
                  start a test →
                </.link>
              </div>
            </div>
          <% else %>
            <div class="rounded-lg bg-base-200/30 border border-base-300/40 overflow-hidden">
              <table class="w-full text-sm font-mono">
                <thead class="bg-base-300/30 text-base-content/50 text-xs uppercase tracking-wider">
                  <tr>
                    <th class="px-4 py-3 text-left w-12">#</th>
                    <th class="px-4 py-3 text-left">name</th>
                    <th class="px-4 py-3 text-right">wpm</th>
                    <th class="px-4 py-3 text-right">acc</th>
                    <th class="px-4 py-3 text-right hidden sm:table-cell">raw</th>
                    <th class="px-4 py-3 text-right hidden md:table-cell">when</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-base-300/30">
                  <%= for {r, idx} <- Enum.with_index(@results, 1) do %>
                    <tr class={["transition-colors hover:bg-base-300/20", idx <= 3 && "bg-primary/5"]}>
                      <td class="px-4 py-3 text-base-content/40 tabular-nums">
                        <%= cond do %>
                          <% idx == 1 -> %>
                            <span class="text-yellow-400">1</span>
                          <% idx == 2 -> %>
                            <span class="text-gray-400">2</span>
                          <% idx == 3 -> %>
                            <span class="text-amber-700">3</span>
                          <% true -> %>
                            {idx}
                        <% end %>
                      </td>
                      <td class="px-4 py-3 truncate max-w-[120px] sm:max-w-none">
                        {r.display_name || "anonymous"}
                      </td>
                      <td class="px-4 py-3 text-right text-primary font-bold tabular-nums">
                        {r.wpm}
                      </td>
                      <td class="px-4 py-3 text-right text-success/80 tabular-nums">{r.accuracy}%</td>
                      <td class="px-4 py-3 text-right text-base-content/50 tabular-nums hidden sm:table-cell">
                        {r.raw_wpm}
                      </td>
                      <td class="px-4 py-3 text-right text-base-content/40 text-xs hidden md:table-cell">
                        {ago(r.inserted_at)}
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp ago(dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86_400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86_400)}d ago"
    end
  end
end
