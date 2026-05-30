defmodule TypingVimWeb.VimIndexLive do
  use TypingVimWeb, :live_view

  alias TypingVim.Vim
  alias TypingVimWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), Presence.topic(), socket.assigns.guest_id, %{
          page: "vim_index",
          joined_at: System.system_time(:second)
        })

      Phoenix.PubSub.subscribe(TypingVim.PubSub, Presence.topic())
    end

    grouped = Vim.list_lessons_grouped()
    solved = Vim.solved_lesson_ids(socket.assigns.guest_id)

    {:ok,
     socket
     |> assign(:page_title, "Vim · TypingVim")
     |> assign(:active, :vim)
     |> assign(:online_count, Presence.online_count())
     |> assign(:grouped, grouped)
     |> assign(:solved, solved)}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_count, Presence.online_count())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} online_count={@online_count} active={@active}>
      <section class="flex-1 px-4 py-8 sm:py-12">
        <div class="max-w-3xl mx-auto space-y-8">
          <header class="text-center space-y-2">
            <h1 class="text-3xl font-bold tracking-tight">vim practice</h1>
            <p class="text-sm text-base-content/50 font-mono">
              learn vim shortcuts by doing — small tasks, gentle hints
            </p>
          </header>

          <div class="md:hidden rounded-lg bg-warning/10 border border-warning/30 text-warning p-6 text-center font-mono text-sm">
            ⌨️ vim mode requires a physical keyboard.<br /> please open on desktop.
          </div>

          <div class="hidden md:block space-y-8">
            <%= for {category, lessons} <- @grouped do %>
              <div class="space-y-3">
                <h2 class="text-xs uppercase tracking-widest text-base-content/40 font-mono pl-2">
                  {category}
                </h2>
                <div class="grid sm:grid-cols-2 gap-3">
                  <%= for lesson <- lessons do %>
                    <.link
                      navigate={~p"/vim/#{lesson.slug}"}
                      class="group p-4 rounded-lg bg-base-200/40 border border-base-300/60 hover:border-primary/50 hover:bg-base-200/70 transition-all"
                    >
                      <div class="flex items-start justify-between gap-2">
                        <div class="flex-1">
                          <div class="font-semibold text-base group-hover:text-primary transition-colors">
                            {lesson.title}
                          </div>
                          <div class="text-xs text-base-content/40 mt-1 font-mono">
                            {difficulty_dots(lesson.difficulty)}
                            <%= if lesson.primary_keys do %>
                              · <span class="text-base-content/60">{lesson.primary_keys}</span>
                            <% end %>
                          </div>
                        </div>
                        <%= if MapSet.member?(@solved, lesson.id) do %>
                          <span class="text-success text-sm" title="solved">✓</span>
                        <% end %>
                      </div>
                    </.link>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp difficulty_dots(n) when is_integer(n) do
    String.duplicate("●", n) <> String.duplicate("○", max(3 - n, 0))
  end
end
