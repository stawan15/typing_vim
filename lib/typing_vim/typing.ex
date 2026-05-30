defmodule TypingVim.Typing do
  @moduledoc """
  Context for typing tests: wordlist, result persistence, leaderboard.
  """
  import Ecto.Query
  alias TypingVim.Repo
  alias TypingVim.Typing.Result

  @wordlist_path Path.expand("../../priv/wordlists/english_1k.json", __DIR__)
  @external_resource @wordlist_path

  @wordlist (case File.read(@wordlist_path) do
               {:ok, body} -> Jason.decode!(body)
               {:error, _} -> ~w(the be of and to in that have it for not on with he as you do at)
             end)

  def wordlist, do: @wordlist

  @doc "Sample n words at random from the wordlist."
  def sample_words(n) when is_integer(n) and n > 0 do
    list = @wordlist
    size = length(list)

    if size == 0 do
      []
    else
      for _ <- 1..n, do: Enum.at(list, :rand.uniform(size) - 1)
    end
  end

  @doc "Generate a fresh test string for a given mode/duration."
  def generate_test(mode, _duration) when mode in ["time", "words"] do
    # For both modes we provide a generous pool; client trims by time/word count
    count =
      case mode do
        "time" -> 80
        "words" -> 80
      end

    sample_words(count) |> Enum.join(" ")
  end

  # --- Results ---

  def create_result(attrs) do
    %Result{}
    |> Result.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Top N results filtered by mode + duration."
  def leaderboard(mode \\ "time", duration \\ 30, limit \\ 20) do
    Result
    |> where([r], r.mode == ^mode and r.duration_sec == ^duration)
    |> order_by([r], desc: r.wpm, desc: r.accuracy)
    |> limit(^limit)
    |> Repo.all()
  end

  def recent_personal_best(guest_id, mode, duration) do
    Result
    |> where([r], r.guest_id == ^guest_id and r.mode == ^mode and r.duration_sec == ^duration)
    |> order_by([r], desc: r.wpm)
    |> limit(1)
    |> Repo.one()
  end

  def total_tests, do: Repo.aggregate(Result, :count, :id)
end
