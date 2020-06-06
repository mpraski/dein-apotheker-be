defmodule Domain.Migration do
  @moduledoc """
  Module defining the database migration
  """

  @app :domain
  @steps 100
  @interval 500

  alias Chat.Translator
  alias Repo.Translation

  defmacrop repeat(fun, steps \\ @steps, interval \\ @interval) do
    quote do
      Enum.reduce_while(1..unquote(steps), false, fn _, _ ->
        case unquote(fun) do
          {:ok, _} ->
            {:halt, true}

          _ ->
            :timer.sleep(unquote(interval))
            {:cont, false}
        end
      end)
    end
  end

  def migrate do
    with rs <- repos() do
      unless rs
             |> Enum.map(&fn -> repeat(trySelect(&1)) end)
             |> Enum.map(&Task.async/1)
             |> Enum.map(&Task.await(&1, @interval * @steps))
             |> Enum.all?() do
        raise "Database connectivity problem"
      end

      for repo <- rs do
        {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
      end

      load_translations()
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp trySelect(repo) do
    try do
      Ecto.Adapters.SQL.query(repo, "SELECT 1")
    rescue
      e in DBConnection.ConnectionError -> e
    end
  end

  defp repos do
    Application.load(@app)
    # This is not in the phoenix documentation, but it's necessary to ensure :ssl is started
    {:ok, _} = Application.ensure_all_started(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_translations do
    Translation.clean()

    for scenario <- Chat.scenarios(),
        language <- Translator.languages() do
      Translation.export(scenario, language)
    end
  end
end
