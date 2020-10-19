defmodule Chat.Scenario.Text do
  @moduledoc """
  Text with dynamic program snippets
  """

  alias Chat.Language.Parser
  alias Chat.Language.Context
  alias Chat.Language.Interpreter

  use TypedStruct

  typedstruct do
    field(:text, binary(), enforce: true)
    field(:substitutes, list(any()), enforce: true, default: [])
  end

  @substitute_regex ~r/\{([^\}]+)\}/

  def new(text) do
    %__MODULE__{
      text: text,
      substitutes: make_substitutes(text)
    }
  end

  def render(module, input \\ nil)

  def render(%__MODULE__{substitutes: [], text: text}, _), do: text

  def render(
        %__MODULE__{
          substitutes: subs,
          text: text
        },
        input
      ) do
    subs
    |> Enum.map(&execute(&1, input))
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

  defp execute(program, input) do
    program = Interpreter.interpret(program)

    Context.new()
    |> program.(input)
    |> to_string()
  end

  defp make_substitutes(text) do
    @substitute_regex
    |> Regex.scan(text)
    |> Enum.map(fn [_, source] -> Parser.parse(source) end)
  end
end
