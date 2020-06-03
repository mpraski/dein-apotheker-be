defmodule Domain.Repo.Migrations.CreateJourney do
  use Ecto.Migration

  def change do
    create table(:journey) do
      add(:token, :string)
      add(:answer, :string)
      add(:answer_type, :string)
      add(:question, :string)
      add(:scenario, :string)
      add(:data, :map)
      add(:answered_at, :utc_datetime_usec)
    end
  end
end