defmodule Chat.Language.StdLib.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.StdLib

  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Language.Parser
  alias Chat.Language.Context
  alias Chat.Driver

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
      program: "c = 3, TO_TEXT(a, 'b', [c])",
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
    ],
    go_1: [
      program: "GO(PreviousMedBrand)",
      expected: quote(do: fn %State{question: q} -> q == :PreviousMedBrand end),
      register: Driver.initial({Chat.scenarios(), Chat.databases()})
    ],
    load_1: [
      program: "LOAD(SomeProcess)",
      expected:
        quote(
          do: fn %State{
                   processes: [
                     _,
                     %StateProcess{
                       id: :SomeProcess
                     }
                   ]
                 } ->
            true
          end
        ),
      register: Driver.initial({Chat.scenarios(), Chat.databases()})
    ],
    load_with_1: [
      program: """
        a = 5,
        b = 'val',
        LOAD_WITH(SomeProcess, a, b)
      """,
      expected:
        quote(
          do: fn %State{
                   processes: [
                     _,
                     %StateProcess{
                       id: :SomeProcess,
                       variables: %{
                         a: 5,
                         b: "val"
                       }
                     }
                   ]
                 } ->
            true
          end
        ),
      register: Driver.initial({Chat.scenarios(), Chat.databases()})
    ],
    load_with_2: [
      program: """
        l = LIST('v1', 'v2', 'v3'),
        FOR v IN [l] DO
          LOAD_WITH(SomeProcess, v)
      """,
      expected:
        quote(
          do: fn %State{
                   processes: [
                     _,
                     %StateProcess{
                       id: :SomeProcess,
                       variables: %{v: "v1"}
                     },
                     %StateProcess{
                       id: :SomeProcess,
                       variables: %{v: "v2"}
                     },
                     %StateProcess{
                       id: :SomeProcess,
                       variables: %{v: "v3"}
                     }
                   ]
                 } ->
            true
          end
        ),
      register: Driver.initial({Chat.scenarios(), Chat.databases()})
    ],
    jump_1: [
      program: "JUMP(SomeProcess)",
      expected:
        quote(
          do: fn %State{
                   processes: [
                     %StateProcess{
                       id: :SomeProcess
                     }
                   ]
                 } ->
            true
          end
        ),
      register: Driver.initial({Chat.scenarios(), Chat.databases()})
    ],
    save_1: [
      program: """
        a = 4,
        b = 'val',
        c = LIST(a, [b], c),
        SAVE(a),
        SAVE(b),
        SAVE(c)
      """,
      expected:
        quote(
          do: fn %State{
                   variables: v
                 } ->
            Map.get(v, :a) == 4 and
              Map.get(v, :b) == "val" and
              Map.get(v, :c) == [:a, "val", :c]
          end
        ),
      register: Driver.initial({Chat.scenarios(), Chat.databases()})
    ]
  ]

  Enum.each(tests, fn {name, data} ->
    @program Keyword.get(data, :program)
    @register Keyword.get(data, :register)
    @expected Keyword.get(data, :expected)

    test "#{name} stdlib test" do
      ctx = Context.new(Chat.scenarios(), Chat.databases())
      result = Parser.parse(@program).(ctx, @register)
      expected = unquote(@expected)

      if is_function(expected) do
        assert expected.(result)
      else
        assert result == expected
      end
    end
  end)
end