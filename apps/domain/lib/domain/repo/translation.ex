defmodule Repo.Translation do
  alias Repo.Translation.Item

  def export(scenario, language) do
    for {k, v} <- Chat.translation(scenario, language) do
      %Item{
        scenario: scenario,
        language: language,
        key: k,
        value: v
      }
      |> Item.changeset(%{})
      |> Domain.Repo.insert()
    end
  end

  def clean do
    Domain.Repo.delete_all(Item)
  end
end
