defmodule TypingVimWeb.Router do
  use TypingVimWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug TypingVimWeb.Plugs.GuestId
    plug :fetch_live_flash
    plug :put_root_layout, html: {TypingVimWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TypingVimWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [{TypingVimWeb.LiveHooks, :assign_guest_id}] do
      live "/", HomeLive
      live "/type", TypingLive
      live "/leaderboard", LeaderboardLive
      live "/vim", VimIndexLive
      live "/vim/:slug", VimLessonLive
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:typing_vim, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TypingVimWeb.Telemetry
    end
  end
end
