defmodule Chat.Scenario.Parser do
  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer}
  alias Chat.Language.Parser, as: ProcessParser

  @scenario_header ~w[Process Action]
  @process_header ~w[ID Type Query Text Action Output]
  @process_columns length(@process_header)

  def parse(scenarios) do
    scenarios
    |> Enum.map(fn {k, v} -> {k, parse_scenario(v)} end)
    |> Enum.into(Map.new())
  end

  defp parse_scenario({
         {
           scenario_name,
           scenario_table
         },
         process_tables
       }) do
    actions =
      [{entry, _} | _] =
      scenario_table
      |> validate_table(@scenario_header)
      |> Enum.map(&parse_actions/1)

    actions = actions |> Enum.into(Map.new())

    processes =
      process_tables
      |> Stream.map(fn {p, r} -> {p, validate_table(r, @process_header)} end)
      |> Stream.map(&parse_process/1)
      |> Stream.map(fn %Process{id: id} = p -> {id, p} end)
      |> Enum.into(Map.new())

    Scenario.new(String.to_atom(scenario_name), entry, actions, processes)
  end

  defp parse_actions([p, a]) do
    {String.to_atom(p), parse_program(a)}
  end

  defp parse_process({p, rows}) do
    reducer = fn
      [nil | _] = row, {qs, as} ->
        {qs, [parse_answer(row) | as]}

      row, {qs, []} ->
        {[parse_question(row) | qs], []}

      row, {[q | qs], as} ->
        q =
          as
          |> Enum.with_index()
          |> Enum.map(fn {a, i} -> %Answer{a | id: :"#{q.id}_#{i}"} end)
          |> Enum.reduce(q, &Question.add_answer/2)

        {[parse_question(row) | [q | qs]], []}
    end

    questions =
      [entry | _] =
      rows
      |> Enum.map(&fit(&1, @process_columns))
      |> Enum.reduce({[], []}, reducer)
      |> elem(0)
      |> Enum.reverse()

    questions =
      questions
      |> Enum.map(fn %Question{id: id} = q -> {id, q} end)
      |> Enum.into(Map.new())

    Process.new(String.to_atom(p), entry.id, questions)
  end

  defp parse_question([id, type, query, text, action, output]) do
    with action <- parse_program(action),
         query <- parse_program(query),
         id <- String.to_atom(id),
         type <- String.to_atom(type),
         output <- parse_question_output(output) do
      Question.new(
        id,
        type,
        query,
        text,
        action,
        output
      )
    end
  end

  defp parse_answer([_, _, _, text, action, output]) do
    with action <- parse_program(action),
         output <- parse_answer_output(output) do
      Answer.new(
        :unknown,
        text,
        action,
        output
      )
    end
  end

  defp parse_program(nil), do: nil

  defp parse_program(source) do
    ProcessParser.parse(source)
  end

  defp parse_question_output(nil), do: nil

  defp parse_question_output(output) do
    output
    |> String.slice(1..-2)
    |> String.to_atom()
  end

  defp parse_answer_output(nil), do: nil

  defp parse_answer_output(output) do
    String.to_atom(output)
  end

  defp validate_table([h | r], header) when h == header, do: r

  defp fit(list, length, base \\ nil) do
    delta = length - length(list)

    extend = fn d, l ->
      with app <-
             0..(d - 1)
             |> Enum.to_list()
             |> Enum.map(fn _ -> base end) do
        l |> Enum.concat(app)
      end
    end

    trim = fn d, l ->
      Enum.take(l, length(l) + d)
    end

    fitter = fn
      d when d == 0 -> list
      d when d > 0 -> extend.(delta, list)
      d when d < 0 -> trim.(delta, list)
    end

    fitter.(delta)
  end
end
