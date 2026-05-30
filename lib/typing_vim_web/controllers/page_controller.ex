defmodule TypingVimWeb.PageController do
  use TypingVimWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
