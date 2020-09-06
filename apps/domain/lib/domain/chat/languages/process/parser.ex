defmodule Chat.Languages.Process.Parser do
  def parse(source) do
    {:ok, tokens, _} = :process_lexer.string(to_charlist(source))
    :process_parser.parse(tokens)
  end
end
