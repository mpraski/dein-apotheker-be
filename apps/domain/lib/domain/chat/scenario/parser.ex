defmodule Chat.Scenario.Parser do
  alias Chat.Data.{Scenario, Process, Question, Answer}
  alias Chat.Languages.Process.Parser

  @scenario_header ~w[Process Action]
  @process_header ~w[ID Type Query Text Action Output]
  @process_columns length(@process_header)

  defmodule Failure do
    defexception message: "XLSX parsing failure"
  end

  def parse_scenario({
        {
          scenario_name,
          scenario_table
        },
        process_tables
      }) do
    actions =
      scenario_table
      |> validate_table(@scenario_header)
      |> Enum.map(&parse_actions/1)
      |> Enum.into(Map.new())

    processes =
      process_tables
      |> Stream.map(fn {p, r} -> {p, validate_table(r, @process_header)} end)
      |> Stream.map(&parse_process/1)
      |> Stream.map(fn %Process{id: id} = p -> {id, p} end)
      |> Enum.into(Map.new())

    Scenario.new(scenario_name, actions, processes)
  end

  defp parse_actions([p, a]) do
    with {:ok, program} <- parse_program(a) do
      {String.to_atom(p), program}
    end
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
      rows
      |> Enum.map(&extend(&1, @process_columns))
      |> Enum.reduce({[], []}, reducer)
      |> elem(0)
      |> Enum.map(fn %Question{id: id} = q -> {id, q} end)
      |> Enum.into(Map.new())

    Process.new(String.to_atom(p), questions)
  end

  defp parse_question([id, type, query, text, action, output]) do
    with {:ok, program} <- parse_program(action),
         id <- String.to_atom(id),
         type <- String.to_atom(type),
         output <- parse_question_output(output) do
      Question.new(
        id,
        type,
        query,
        text,
        program,
        output
      )
    end
  end

  defp parse_answer([_, _, _, text, action, output]) do
    with {:ok, program} <- parse_program(action),
         output <- parse_answer_output(output) do
      Answer.new(
        :unknown,
        text,
        program,
        output
      )
    end
  end

  defp parse_program(nil), do: {:ok, nil}

  defp parse_program(source) do
    Parser.parse(source)
  end

  defp parse_question_output(nil), do: nil

  defp parse_question_output(output) do
    output
    |> String.slice(1..-2)
    |> String.to_atom()
  end

  defp parse_answer_output(nil), do: nil

  defp parse_answer_output(output) do
    output |> String.to_atom()
  end

  defp validate_table([h | r], header) do
    if h == header do
      r
    else
      raise Failure, message: "failed to parse scenario, wrong header #{h}"
    end
  end

  defp extend(list, length, base \\ nil) do
    rem = abs(Enum.count(list) - length)

    if rem == 0 do
      list
    else
      with app <-
             0..(rem - 1)
             |> Enum.to_list()
             |> Enum.map(fn _ -> base end) do
        list |> Enum.concat(app)
      end
    end
  end
end
