defmodule Chat do
  @moduledoc """
  Chat consolidates commonnly used data and function
  """

  alias Chat.Loader
  alias Chat.Scenario.Process
  alias Chat.Scenario.Question

  @scenario_path Application.get_env(:chat, :scenario_path)
  @database_path Application.get_env(:chat, :database_path)

  @data Loader.load(@scenario_path, @database_path)

  Enum.each(elem(@data, 0), fn {k, v} ->
    def scenario(unquote(k)), do: unquote(Macro.escape(v))

    Enum.each(v.processes, fn {a, b} ->
      def process(unquote(k), unquote(a)), do: unquote(Macro.escape(b))

      Enum.each(b.questions, fn {c, d} ->
        def question(unquote(k), unquote(a), unquote(c)), do: unquote(Macro.escape(d))
      end)
    end)
  end)

  Enum.each(elem(@data, 1), fn {k, v} ->
    def database(unquote(k)), do: unquote(Macro.escape(v))
  end)

  def question_id(scenario_id, process_id) do
    {:ok, %Question{id: question_id}} = process(scenario_id, process_id) |> Process.entry()

    question_id
  end
end
