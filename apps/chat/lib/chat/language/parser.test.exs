defmodule Chat.Language.Parser.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.Parser

  alias Chat.Language.Parser
  alias Chat.Language.Context
  alias Chat.Language.Interpreter

  test "parse nil program" do
    catch_error(Parser.parse(nil))
  end

  test "parse invalid program" do
    catch_error(Parser.parse(""))
  end

  test "parse valid program" do
    prog = Parser.parse("'hello there'")
    prog = Interpreter.interpret(prog)
    ctx = Context.new(Chat.data())

    assert is_function(prog)
    assert prog.(ctx, nil) == "hello there"
  end
end
