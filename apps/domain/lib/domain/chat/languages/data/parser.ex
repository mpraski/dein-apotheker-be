defmodule Chat.Languages.Data.Parser do
  def parse(source) do
    {:ok, tokens, _} = :data_lexer.string(to_charlist(source))
    :data_parser.parse(tokens)
  end
end
