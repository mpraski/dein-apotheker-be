defmodule Chat.Language.Parser do
  alias Chat.Language.Interpreter

  def parse(source) do
    {:ok, tokens, _} = source |> to_charlist() |> :process_lexer.string()
    {:ok, ast} = :process_parser.parse(tokens)

    Interpreter.interpret(ast)
  end
end
