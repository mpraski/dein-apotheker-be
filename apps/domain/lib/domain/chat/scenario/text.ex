defmodule Chat.Scenario.Text do
  alias Chat.State

  alias Chat.Language.Parser
  alias Chat.Language.Interpreter
  alias Chat.Language.Interpreter.Context

  use TypedStruct

  typedstruct do
    field(:text, binary(), enforce: true)
    field(:substitutes, list({:var | :prog, any()}), enforce: true, default: [])
  end

  @substitute_regex ~r/\{(var|prog)\}\{([^\}]*)\}/

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
        scenarios,
        databases
      ) do
    subs
    |> Enum.map(&execute(&1, state, scenarios, databases))
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

  defp execute({:var, var}, %State{} = s, _, _) do
    {:ok, value} = State.get_var(s, var)
    value
  end

  defp execute({:prog, program}, state, scenarios, databases) do
    Context.new(scenarios, databases) |> program.(state) |> to_string()
  end

  defp make_substitutes(text) do
    @substitute_regex
    |> Regex.scan(text)
    |> Enum.map(fn [_, kind, action] -> parse(kind, action) end)
  end

  defp parse("var", var), do: {:var, String.to_atom(var)}

  defp parse("prog", source) do
    {:ok, program} = Parser.parse(source)
    {:prog, Interpreter.interpret(program)}
  end
end
