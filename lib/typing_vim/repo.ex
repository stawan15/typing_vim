defmodule TypingVim.Repo do
  use Ecto.Repo,
    otp_app: :typing_vim,
    adapter: Ecto.Adapters.Postgres
end
