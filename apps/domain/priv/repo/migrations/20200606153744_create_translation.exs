defmodule Domain.Repo.Migrations.CreateTranslation do
  use Ecto.Migration

  def change do
    create table(:translation) do
      add(:scenario, :string)
      add(:language, :string)
      add(:key, :string)
      add(:value, :text)
    end
  end
end
