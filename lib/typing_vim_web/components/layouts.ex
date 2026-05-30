defmodule TypingVimWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use TypingVimWeb, :html

  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :online_count, :integer, default: nil
  attr :active, :atom, default: nil

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col">
      <header class="border-b border-base-300/60 backdrop-blur-sm sticky top-0 z-50 bg-base-100/80">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 h-14 flex items-center justify-between">
          <.link navigate={~p"/"} class="flex items-center gap-2 group">
            <span class="text-lg font-bold tracking-tight">
              <span class="text-primary">typing</span><span class="text-accent">vim</span>
            </span>
          </.link>

          <nav class="flex items-center gap-1 text-sm">
            <.nav_link to={~p"/type"} active={@active == :type}>type</.nav_link>
            <.nav_link to={~p"/vim"} active={@active == :vim} class="hidden md:inline-flex">
              vim
            </.nav_link>
            <.nav_link to={~p"/leaderboard"} active={@active == :leaderboard}>top</.nav_link>
          </nav>

          <div class="flex items-center gap-3 text-xs">
            <%= if @online_count do %>
              <div class="flex items-center gap-1.5 px-2 py-1 rounded-full bg-base-200/60 border border-base-300/60">
                <span class="relative flex size-2">
                  <span class="absolute inline-flex h-full w-full animate-ping rounded-full bg-success opacity-75">
                  </span>
                  <span class="relative inline-flex size-2 rounded-full bg-success"></span>
                </span>
                <span class="font-mono tabular-nums">{@online_count} online</span>
              </div>
            <% end %>
          </div>
        </div>
      </header>

      <main class="flex-1 flex flex-col">
        {render_slot(@inner_block)}
      </main>

      <footer class="border-t border-base-300/60 py-4 text-center text-xs text-base-content/40">
        built with phoenix + liveview · type fast, vim faster
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  attr :to, :string, required: true
  attr :active, :boolean, default: false
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def nav_link(assigns) do
    ~H"""
    <.link
      navigate={@to}
      class={[
        "px-3 py-1.5 rounded-md transition-colors font-mono",
        @active && "bg-base-200 text-primary",
        !@active && "text-base-content/60 hover:text-base-content hover:bg-base-200/60",
        @class
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
