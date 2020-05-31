defmodule Chat.Journey.Record do
  use Ecto.Schema

  @fields ~w[token answer answer_type question scenario data when]a

  schema "journey" do
    field(:token, :string)
    field(:answer, :string)
    field(:answer_type, :string)
    field(:question, :string)
    field(:scenario, :string)
    field(:data, :map)
    field(:when, :utc_datetime_usec)
  end

  def changeset(record, params \\ %{}) do
    record
    |> Ecto.Changeset.cast(params, @fields)
    |> Ecto.Changeset.validate_required(@fields)
  end
end
