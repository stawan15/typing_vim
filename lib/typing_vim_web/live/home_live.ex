defmodule TypingVimWeb.HomeLive do
  use TypingVimWeb, :live_view

  alias TypingVim.Typing
  alias TypingVimWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), Presence.topic(), socket.assigns.guest_id, %{
          page: "home",
          joined_at: System.system_time(:second)
        })

      Phoenix.PubSub.subscribe(TypingVim.PubSub, Presence.topic())
    end

    {:ok,
     socket
     |> assign(:page_title, "TypingVim")
     |> assign(:active, :home)
     |> assign(:online_count, Presence.online_count())
     |> assign(:total_tests, Typing.total_tests())}
  end

  @impl true
  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_count, Presence.online_count())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} online_count={@online_count} active={@active}>
      <section class="flex-1 flex flex-col items-center justify-center px-4 py-16 sm:py-24">
        <div class="max-w-3xl w-full text-center space-y-8">
          <div class="space-y-3">
            <h1 class="text-5xl sm:text-7xl font-bold tracking-tight">
              <span class="text-primary">type</span><span class="text-accent">vim</span>
            </h1>
            <p class="text-base-content/60 text-lg sm:text-xl font-mono">
              type fast. learn vim. no signup.
            </p>
          </div>

          <div class="flex flex-col sm:flex-row gap-3 justify-center pt-4">
            <.link
              navigate={~p"/type"}
              class="px-8 py-4 rounded-lg bg-primary text-primary-content font-semibold hover:bg-primary/90 transition-all hover:scale-[1.02] shadow-lg shadow-primary/20"
            >
              start typing test
            </.link>
            <.link
              navigate={~p"/vim"}
              class="hidden md:inline-flex px-8 py-4 rounded-lg bg-base-200 border border-base-300 hover:bg-base-300 transition-all hover:scale-[1.02] font-semibold"
            >
              practice vim
            </.link>
          </div>

          <p class="md:hidden text-xs text-warning/80 font-mono pt-2">
            vim mode requires desktop keyboard
          </p>

          <div class="grid grid-cols-2 gap-4 pt-12 max-w-md mx-auto text-sm">
            <div class="p-4 rounded-lg bg-base-200/50 border border-base-300/60">
              <div class="text-2xl font-bold font-mono text-primary tabular-nums">
                {@total_tests}
              </div>
              <div class="text-xs text-base-content/50 uppercase tracking-wider mt-1">
                tests completed
              </div>
            </div>
            <div class="p-4 rounded-lg bg-base-200/50 border border-base-300/60">
              <div class="text-2xl font-bold font-mono text-success tabular-nums">
                {@online_count}
              </div>
              <div class="text-xs text-base-content/50 uppercase tracking-wider mt-1">
                online now
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
