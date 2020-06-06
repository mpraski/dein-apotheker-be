defmodule Repo.Translation.Item do
  use Ecto.Schema

  @fields ~w[scenario language key value]a

  schema "translation" do
    field(:scenario, :string)
    field(:language, :string)
    field(:key, :string)
    field(:value, :string)
  end

  def changeset(item, params \\ %{}) do
    item
    |> Ecto.Changeset.cast(params, @fields)
    |> Ecto.Changeset.validate_required(@fields)
  end
end
