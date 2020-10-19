defmodule Chat.Language.Parser do
  @moduledoc """
  Parser is a convenience module for parsing programs
  """

  def parse(source) do
    {:ok, tokens, _} = source |> to_charlist() |> :process_lexer.string()
    {:ok, ast} = :process_parser.parse(tokens)

    ast
  end
end
