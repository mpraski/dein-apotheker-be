defmodule Chat.Language.Parser.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.Parser

  alias Chat.Language.Parser
  alias Chat.Language.Interpreter

  import Parser

  test "parse nil program" do
    catch_error(Parser.parse(nil))
  end

  test "parse invalid program" do
    catch_error(Parser.parse(""))
  end

  test "parse valid program" do
    prog = Parser.parse("'hello there'")
    prog = Interpreter.interpret(prog)

    assert is_function(prog)
    assert prog.(nil) == "hello there"
  end

  test "use sigil" do
    prog = ~p/'hello there'/
    prog = Interpreter.interpret(prog)

    assert is_function(prog)
    assert prog.(nil) == "hello there"
  end

  test "use multiline sigil" do
    prog = ~p"""
      'hello there'
    """

    prog = Interpreter.interpret(prog)

    assert is_function(prog)
    assert prog.(nil) == "hello there"
  end
end
