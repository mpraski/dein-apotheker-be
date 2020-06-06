defmodule Repo.Journey.Item do
  use Ecto.Schema

  @fields ~w[token answer answer_type question scenario data answered_at]a

  schema "journey" do
    field(:token, :string)
    field(:answer, :string)
    field(:answer_type, :string)
    field(:question, :string)
    field(:scenario, :string)
    field(:data, :map)
    field(:answered_at, :utc_datetime_usec)
  end

  def changeset(item, params \\ %{}) do
    item
    |> Ecto.Changeset.cast(params, @fields)
    |> Ecto.Changeset.validate_required(@fields)
  end
end
