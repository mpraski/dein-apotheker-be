defmodule Chat.Language.StdLib.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.StdLib

  alias Chat.State
  alias Chat.State.Process, as: StateProcess
  alias Chat.Language.Parser
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
      program: "c = 3; TO_TEXT(a, 'b', [c])",
      expected: "a b 3"
    ],
    to_text_5: [
      program: "TO_TEXT({a, b, c, {d, e, {f}}})",
      expected: "a b c d e f"
    ],
    list_1: [
      program: "a = 1; b = 2; {[a], [b], c}",
      expected: [1, 2, :c]
    ],
    index_1: [
      program: "a = 1; b = 2; l = {[a], [b], c}; INDEX(0, [l])",
      expected: 1
    ],
    index_2: [
      program: "a = 1; b = 2; l = {[a], [b], c}; INDEX(1, [l])",
      expected: 2
    ],
    index_3: [
      program: "a = 1; b = 2; l = {[a], [b], c}; INDEX(2, [l])",
      expected: :c
    ],
    size_1: [
      program: "SIZE({a, 'b', 3})",
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
      program: "a = 1; b = 2; [a] + [b]",
      expected: 3
    ],
    go_1: [
      program: "GO(PreviousMedBrand)",
      expected: quote(do: fn %State{question: q} -> q == :PreviousMedBrand end),
      register: Driver.initial()
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
      register: Driver.initial()
    ],
    load_with_1: [
      program: """
        a = 5;
        b = 'val';
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
      register: Driver.initial()
    ],
    load_with_2: [
      program: """
        l = {'v1', 'v2', 'v3'};
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
      register: Driver.initial()
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
      register: Driver.initial() |> Memory.store(:cart, [:prod_1, :prod_2, :prod_3])
    ],
    inject_with_1: [
      program: """
        LOAD(ExampleProcess);
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
      register: Driver.initial() |> Memory.store(:cart, [:prod_1, :prod_2, :prod_3])
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
      register: Driver.initial()
    ],
    jump_2: [
      program: "LOAD(ExampleProcess); JUMP(ExampleProcess)",
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
      register: Driver.initial()
    ],
    save_1: [
      program: """
        a = 4;
        b = 'val';
        c = {a, [b], c};
        SAVE(a);
        SAVE(b);
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
      register: Driver.initial()
    ],
    delete_1: [
      program: """
        DELETE(some_key)
      """,
      expected:
        quote(
          do: fn %State{
                   variables: %{}
                 } ->
            true
          end
        ),
      register: Driver.initial() |> Memory.store(:some_key, 5)
    ],
    finish_1: [
      program: """
        LOAD(ExampleProcess);
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
      register: Driver.initial()
    ],
    cart_1: [
      program: """
        cart = {'1', '2', '3'};
        SAVE(cart);
        product_id = '4';
        CART()
      """,
      expected:
        quote(
          do: fn %State{
                   variables: variables
                 } ->
            cart_items = ["1", "2", "3", "4"]

            {:ok, cart} = variables |> Memory.load(:cart)

            cart == cart_items
          end
        ),
      register: Driver.initial()
    ],
    cart_2: [
      program: """
        cart = {'1', '2', '3'};
        SAVE(cart);
        product_id = '2';
        CART()
      """,
      expected:
        quote(
          do: fn %State{
                   variables: variables
                 } ->
            cart_items = ["1", "2", "3"]

            {:ok, cart} = variables |> Memory.load(:cart)

            cart == cart_items
          end
        ),
      register: Driver.initial()
    ],
    cart_3: [
      program: """
        cart = {};
        SAVE(cart);
        product_id = '2';
        CART()
      """,
      expected:
        quote(
          do: fn %State{
                   variables: variables
                 } ->
            cart_items = ["2"]

            {:ok, cart} = variables |> Memory.load(:cart)

            cart == cart_items
          end
        ),
      register: Driver.initial()
    ]
  ]

  Enum.each(tests, fn {name, data} ->
    @program Keyword.get(data, :program)
    @register Keyword.get(data, :register)
    @expected Keyword.get(data, :expected)

    test "#{name} stdlib test" do
      prog = Parser.parse(@program) |> Interpreter.interpret()
      result = prog.(@register)
      expected = unquote(@expected)

      if is_function(expected) do
        assert expected.(result)
      else
        assert result == expected
      end
    end
  end)
end
