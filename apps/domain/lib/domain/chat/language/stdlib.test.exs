defmodule Chat.Language.StdLib.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.StdLib

  alias Chat.Language.Parser
  alias Chat.Language.Context

  tests = [
    to_text_1: [
      program: "TO_TEXT()",
      expected: ""
    ],
    to_text_2: [
      program: "TO_TEXT(a)",
      expected: "a"
    ],
    to_text_3: [
      program: "TO_TEXT(a, 'b')",
      expected: "a b"
    ],
    to_text_4: [
      program: "TO_TEXT(a, 'b', 3)",
      expected: "a b 3"
    ],
    size_1: [
      program: "SIZE(LIST(a, 'b', 3))",
      expected: 3
    ],
    cols_1: [
      program: "COLS(SELECT * FROM Products)",
      expected: 5
    ],
    rows_1: [
      program: "ROWS(SELECT * FROM Products)",
      expected: 3
    ]
  ]

  Enum.each(tests, fn {name, data} ->
    @program Keyword.get(data, :program)
    @register Keyword.get(data, :register)
    @expected Keyword.get(data, :expected)

    test "#{name} stdlib test" do
      ctx = Context.new(Chat.scenarios(), Chat.databases())
      assert Parser.parse(@program).(ctx, @register) == @expected
    end
  end)
end
