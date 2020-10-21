defmodule Chat.Scenario.Parser do
  @moduledoc """
  Parser of the scenarios
  """

  alias Chat.Scenario
  alias Chat.Scenario.{Process, Question, Answer}
  alias Chat.Language.Parser, as: ProcessParser

  @scenario_header ~w[Process Action]
  @process_header ~w[ID Type Query Text Action Output]
  @process_columns length(@process_header)
  @empties [nil, ""]

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
      |> extract_table(@scenario_header)
      |> Enum.map(&parse_actions/1)

    actions = actions |> Enum.into(Map.new())

    processes =
      process_tables
      |> Stream.map(fn {p, r} -> {p, extract_table(r, @process_header)} end)
      |> Stream.map(&parse_process/1)
      |> Stream.map(fn %Process{id: id} = p -> {id, p} end)
      |> Enum.into(Map.new())

    Scenario.new(String.to_atom(scenario_name), entry, actions, processes)
  end

  defp parse_actions([p, a]) do
    {String.to_atom(p), parse_program(a)}
  end

  defp parse_process({p, rows}) do
    mapper = fn question, answers ->
      answers
      |> Stream.with_index()
      |> Stream.map(fn {a, i} -> %Answer{a | id: :"#{question.id}_#{i}"} end)
      |> Enum.reduce(question, &Question.add_answer/2)
    end

    reducer = fn
      [id | [type | _]], acc when id in @empties and type in @empties ->
        acc

      [_ | ["A" | _]] = row, {qs, as} ->
        {qs, [parse_answer(row) | as]}

      row, {qs, []} ->
        {[parse_question(row) | qs], []}

      row, {[q | qs], as} ->
        {[parse_question(row) | [mapper.(q, as) | qs]], []}
    end

    {questions, answers} =
      rows
      |> Stream.map(&fit(&1, @process_columns))
      |> Stream.map(&trim_row/1)
      |> Enum.reduce({[], []}, reducer)

    questions =
      if length(answers) > 0 do
        [q | r] = questions

        [mapper.(q, answers) | r]
      else
        questions
      end

    questions = [entry | _] = questions |> Enum.reverse()

    questions =
      questions
      |> Enum.map(fn %Question{id: id} = q -> {id, q} end)
      |> Enum.into(Map.new())

    Process.new(String.to_atom(p), entry.id, questions)
  end

  defp parse_question([id, type, query, text, action, output]) do
    action = parse_program(action)
    query = parse_program(query)
    id = String.to_atom(id)
    type = String.to_atom(type)
    output = parse_question_output(output)

    Question.new(
      id,
      type,
      query,
      text,
      action,
      output
    )
  end

  defp parse_answer([_, _, _, text, action, output]) do
    Answer.new(
      :unknown,
      text,
      parse_program(action),
      parse_answer_output(output)
    )
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

  defp extract_table([h | r], expected) do
    h = h |> Enum.map(&String.trim/1)

    indices = expected |> Enum.map(&header_index(h, &1))

    Enum.map(r, fn row ->
      indices |> Enum.map(&Enum.at(row, &1))
    end)
  end

  defp header_index(h, n) do
    h |> Enum.find_index(&(&1 == n)) || raise "column #{n} does not exist"
  end

  defp fit(list, length, base \\ nil) do
    delta = length - length(list)

    extend = fn d, l ->
      app =
        0..(d - 1)
        |> Enum.to_list()
        |> Enum.map(fn _ -> base end)

      l |> Enum.concat(app)
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

  defp trim_row(row) do
    trimmer = fn
      nil -> nil
      b when is_binary(b) -> String.trim(b)
    end

    row |> Enum.map(trimmer)
  end
end
