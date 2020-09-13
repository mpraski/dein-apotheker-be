defmodule Chat.Scenario.Text do
  alias Chat.State
  alias Chat.Database
  alias Chat.Languages.Data.Parser, as: DataParser
  alias Chat.Languages.Data.Interpreter, as: DataInterpreter
  alias Chat.Languages.Data.Interpreter.Context, as: DataContext

  @substitute_regex ~r/\{(var|data)\}\{([^\}]*)\}/

  @enforce_keys ~w[text substitutes]a

  defstruct text: "", substitutes: []

  defmodule Failure do
    defexception message: "Text substitution failure"
  end

  def new(text) do
    %__MODULE__{
      text: text,
      substitutes: make_substitutes(text)
    }
  end

  def render(%__MODULE__{substitutes: [], text: text}, _, _), do: text

  def render(
        %__MODULE__{
          substitutes: subs,
          text: text
        },
        %State{} = state,
        databases
      ) do
    subs
    |> materialize(state, databases)
    |> Enum.reduce(text, fn sub, text ->
      Regex.replace(
        @substitute_regex,
        text,
        fn _, _ -> sub end,
        global: false
      )
    end)
  end

  defp materialize(substitutes, %State{} = s, databases) do
    substitutes |> Enum.map(&execute(&1, s, databases))
  end

  defp execute({:var, var}, %State{} = s, _) do
    case State.get_var(s, var) do
      {:ok, value} -> value
      _ -> raise Failure, message: "variable #{var} not defined"
    end
  end

  defp execute({:data, program}, %State{} = s, databases) do
    result =
      program.(%DataContext{
        state: s,
        databases: databases
      })

    case result do
      %Database{rows: [row]} -> Enum.join(row, ", ")
      _ -> raise Failure, message: "DB query didn't return exactly one row"
    end
  end

  defp make_substitutes(text) do
    @substitute_regex
    |> Regex.scan(text)
    |> Enum.map(fn [_, kind, action] -> {type(kind), action} end)
    |> Enum.map(&parse/1)
  end

  defp parse({:var, var}), do: {:var, String.to_atom(var)}

  defp parse({:data, source}) do
    {:ok, program} = DataParser.parse(source)
    {:data, DataInterpreter.interpret(program)}
  end

  defp type("var"), do: :var

  defp type("data"), do: :data
end
