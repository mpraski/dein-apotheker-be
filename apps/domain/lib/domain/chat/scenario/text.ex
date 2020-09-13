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
    |> Enum.map(&execute(&1, state, databases))
    |> Enum.reduce(
      text,
      &Regex.replace(
        @substitute_regex,
        &2,
        fn _, _ -> &1 end,
        global: false
      )
    )
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
    |> Enum.map(fn [_, kind, action] -> parse(kind, action) end)
  end

  defp parse("var", var), do: {:var, String.to_atom(var)}

  defp parse("data", source) do
    {:ok, program} = DataParser.parse(source)
    {:data, DataInterpreter.interpret(program)}
  end
end
