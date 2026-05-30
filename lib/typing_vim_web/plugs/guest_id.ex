defmodule TypingVimWeb.Plugs.GuestId do
  @moduledoc """
  Ensures every visitor has a stable guest_id stored in the session.
  This identity lets us attribute typing results / vim attempts without auth.
  """
  import Plug.Conn

  @key "guest_id"

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, @key) do
      nil ->
        id = generate_id()

        conn
        |> put_session(@key, id)
        |> assign(:guest_id, id)

      id ->
        assign(conn, :guest_id, id)
    end
  end

  defp generate_id do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
