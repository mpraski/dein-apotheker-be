defmodule Chat.Language.StdLib.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.StdLib

  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Language.Parser
  alias Chat.Language.Context
  alias Chat.Language.Memory
  alias Chat.Language.Interpreter
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
    to_text_5: [
      program: "TO_TEXT(LIST(a, b, c, LIST(d, e, LIST(f))))",
      expected: "a b c d e f"
    ],
    list_1: [
      program: "a = 1, b = 2, LIST([a], [b], c)",
      expected: [1, 2, :c]
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
    add_1: [
      program: "a = 1, b = 2, ADD([a], [b])",
      expected: 3
    ],
    go_1: [
      program: "GO(PreviousMedBrand)",
      expected: quote(do: fn %State{question: q} -> q == :PreviousMedBrand end),
      register: Driver.initial(Chat.data())
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
      register: Driver.initial(Chat.data())
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
      register: Driver.initial(Chat.data())
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
      register: Driver.initial(Chat.data())
    ],
    load_with_3: [
      program: """
        FOR item IN [cart] DO
          LOAD_WITH(Explain, item)
      """,
      expected:
        quote(
          do: fn %State{
                   processes: [
                     _,
                     %StateProcess{
                       id: :Explain,
                       variables: %{item: :prod_1}
                     },
                     %StateProcess{
                       id: :Explain,
                       variables: %{item: :prod_2}
                     },
                     %StateProcess{
                       id: :Explain,
                       variables: %{item: :prod_3}
                     }
                   ]
                 } ->
            true
          end
        ),
      register:
        Chat.data()
        |> Driver.initial()
        |> Memory.store(State.cart(), [:prod_1, :prod_2, :prod_3])
    ],
    inject_with_1: [
      program: """
        LOAD(ExampleProcess),
        FOR item IN [cart] DO
          INJECT_WITH(Explain, item)
      """,
      expected:
        quote(
          do: fn %State{
                   processes: [
                     _,
                     %StateProcess{
                       id: :Explain,
                       variables: %{item: :prod_3}
                     },
                     %StateProcess{
                       id: :Explain,
                       variables: %{item: :prod_2}
                     },
                     %StateProcess{
                       id: :Explain,
                       variables: %{item: :prod_1}
                     },
                     %StateProcess{
                       id: :ExampleProcess
                     }
                   ]
                 } ->
            true
          end
        ),
      register:
        Chat.data()
        |> Driver.initial()
        |> Memory.store(State.cart(), [:prod_1, :prod_2, :prod_3])
    ],
    jump_1: [
      program: "JUMP(ExampleProcess)",
      expected:
        quote(
          do: fn %State{
                   question: :time,
                   processes: [
                     %StateProcess{
                       id: :ExampleProcess
                     }
                   ]
                 } ->
            true
          end
        ),
      register: Driver.initial(Chat.data())
    ],
    jump_2: [
      program: "LOAD(ExampleProcess), JUMP(ExampleProcess)",
      expected:
        quote(
          do: fn %State{
                   question: :time,
                   processes: [
                     %StateProcess{
                       id: :ExampleProcess
                     },
                     %StateProcess{
                       id: :ExampleProcess
                     }
                   ]
                 } ->
            true
          end
        ),
      register: Driver.initial(Chat.data())
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
      register: Driver.initial(Chat.data())
    ],
    finish_1: [
      program: """
        LOAD(ExampleProcess),
        FINISH()
      """,
      expected:
        quote(
          do: fn %State{
                   question: :time,
                   processes: [
                     %StateProcess{
                       id: :ExampleProcess
                     }
                   ]
                 } ->
            true
          end
        ),
      register: Driver.initial(Chat.data())
    ]
  ]

  Enum.each(tests, fn {name, data} ->
    @program Keyword.get(data, :program)
    @register Keyword.get(data, :register)
    @expected Keyword.get(data, :expected)

    test "#{name} stdlib test" do
      ctx = Context.new(Chat.scenarios(), Chat.databases())
      prog = Parser.parse(@program) |> Interpreter.interpret()
      result = prog.(ctx, @register)
      expected = unquote(@expected)

      if is_function(expected) do
        assert expected.(result)
      else
        assert result == expected
      end
    end
  end)
end
