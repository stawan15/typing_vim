defmodule TypingVim.Typing.Result do
  use Ecto.Schema
  import Ecto.Changeset

  @modes ~w(time words)
  @durations [15, 30, 60, 120]

  schema "typing_results" do
    field :guest_id, :string
    field :display_name, :string
    field :mode, :string
    field :duration_sec, :integer
    field :word_count, :integer
    field :wpm, :float
    field :raw_wpm, :float
    field :accuracy, :float
    field :correct_chars, :integer
    field :incorrect_chars, :integer

    timestamps(type: :utc_datetime)
  end

  def changeset(result, attrs) do
    result
    |> cast(attrs, [
      :guest_id,
      :display_name,
      :mode,
      :duration_sec,
      :word_count,
      :wpm,
      :raw_wpm,
      :accuracy,
      :correct_chars,
      :incorrect_chars
    ])
    |> validate_required([
      :guest_id,
      :mode,
      :duration_sec,
      :word_count,
      :wpm,
      :raw_wpm,
      :accuracy,
      :correct_chars,
      :incorrect_chars
    ])
    |> validate_inclusion(:mode, @modes)
    |> validate_inclusion(:duration_sec, @durations)
    |> validate_number(:wpm, greater_than_or_equal_to: 0, less_than: 500)
    |> validate_number(:accuracy, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_length(:display_name, max: 24)
    |> update_change(:display_name, &sanitize_name/1)
  end

  defp sanitize_name(nil), do: nil

  defp sanitize_name(name) when is_binary(name) do
    name
    |> String.trim()
    |> case do
      "" -> nil
      s -> String.slice(s, 0, 24)
    end
  end
end
