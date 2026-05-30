defmodule TypingVimWeb.Presence do
  @moduledoc """
  Tracks online users via Phoenix.Presence on the "lobby" topic.
  """
  use Phoenix.Presence,
    otp_app: :typing_vim,
    pubsub_server: TypingVim.PubSub

  @topic "lobby"

  def topic, do: @topic

  def online_count do
    @topic
    |> list()
    |> map_size()
  end
end
