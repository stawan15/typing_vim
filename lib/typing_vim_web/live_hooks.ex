defmodule TypingVimWeb.LiveHooks do
  @moduledoc """
  on_mount hooks attached to LiveViews via the router's live_session.
  Lifts the guest_id from the HTTP session into the LiveView socket.
  """
  import Phoenix.Component, only: [assign: 3]

  def on_mount(:assign_guest_id, _params, session, socket) do
    guest_id = Map.get(session, "guest_id", "anon-#{:rand.uniform(1_000_000_000)}")
    {:cont, assign(socket, :guest_id, guest_id)}
  end
end
