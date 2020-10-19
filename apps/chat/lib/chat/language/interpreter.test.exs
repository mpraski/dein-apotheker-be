defmodule Chat.Language.Interpreter.Test do
  use ExUnit.Case, async: true
  doctest Chat.Language.Interpreter

  alias Chat.Database
  alias Chat.Language.Parser
  alias Chat.Language.Context
  alias Chat.Language.Interpreter

  tests = [
    identifier: [
      program: "some_ident",
      expected: :some_ident
    ],
    string: [
      program: "'some string!?'",
      expected: "some string!?"
    ],
    number: [
      program: "12321",
      expected: 12_321
    ],
    nil_variable: [
      program: "[undefined]",
      expected: nil
    ],
    comp_expression_1: [
      program: "(2 > 1)",
      expected: true
    ],
    comp_expression_2: [
      program: "(1 > 2)",
      expected: false
    ],
    comp_expression_3: [
      program: "(3 >= 3)",
      expected: true
    ],
    comp_expression_4: [
      program: "(3 <= 3)",
      expected: true
    ],
    comp_expression_5: [
      program: "(3 == 3)",
      expected: true
    ],
    comp_expression_6: [
      program: "(3 != 3)",
      expected: false
    ],
    logical_expression_1: [
      program: "((1 == 1) OR (2 == 1))",
      expected: true
    ],
    logical_expression_2: [
      program: "((1 == 1) AND (2 == 1))",
      expected: false
    ],
    decl_expression_1: [
      program: "v = 1, [v]",
      expected: 1
    ],
    decl_expression_2: [
      program: "v = 1, c = [v], [c]",
      expected: 1
    ],
    if_expression_1: [
      program: """
        var1 = 'val',
        IF ([var1] == 'val') THEN 1 ELSE 2
      """,
      expected: 1
    ],
    if_expression_2: [
      program: """
        var1 = 'val',
        IF ([var1] != 'val') THEN 1 ELSE 2
      """,
      expected: 2
    ],
    if_expression_3: [
      program: """
        var1 = 'val',
        var2 = 'val2',
        IF (
          ([var1] == 'val2')
          OR
          ([var2] == 'val2')
        ) THEN 1 ELSE 2
      """,
      expected: 1
    ],
    if_expression_4: [
      program: """
        var1 = 'val',
        var2 = 'val2',
        IF (
          ([var1] == 'val2')
          AND
          ([var2] == 'val2')
        ) THEN 1 ELSE 2
      """,
      expected: 2
    ],
    if_expression_5: [
      program: """
        var1 = 'val',
        var2 = 'val2',
        IF ([var1] == 'val2') THEN 1
          ELIF ([var2] == 'val2') THEN 2
          ELSE 3
      """,
      expected: 2
    ],
    if_expression_6: [
      program: """
        var1 = 'val',
        var2 = 'val3',
        IF ([var1] == 'val2') THEN 1
          ELIF ([var2] == 'val2') THEN 2
          ELSE 3
      """,
      expected: 3
    ],
    if_expression_7: [
      program: """
        var1 = 'val',
        var2 = 'val3',
        IF [var1] THEN 1
          ELIF [var2] THEN 2
          ELSE 3
      """,
      expected: 1
    ],
    if_expression_8: [
      program: """
        var1 = 'val',
        var2 = 'val3',
        IF [var1] THEN (a = 5, ADD([a], 1))
          ELIF [var2] THEN 2
          ELSE 3
      """,
      expected: 6
    ],
    if_expression_9: [
      program: """
        IF [var1] THEN (a = 5, ADD([a], 1))
          ELIF [var2] THEN 2
          ELSE (a = 1, ADD([a], 1))
      """,
      expected: 2
    ],
    for_expr_1: [
      program: """
      j = 0,
      FOR i IN LIST(1, 2, 3)
        DO (j = ADD([j], [i])),
      [j]
      """,
      expected: 6
    ],
    for_expr_2: [
      program: """
      j = 0,
      l = LIST(1, 2, 3),
      FOR i IN [l]
        DO (j = ADD([j], [i])),
      [j]
      """,
      expected: 6
    ],
    select_all_products: [
      program: "SELECT * FROM Products",
      expected: Map.get(Chat.databases(), :Products)
    ],
    select_all_brands: [
      program: "SELECT * FROM Brands",
      expected: Map.get(Chat.databases(), :Brands)
    ],
    select_all_fav_products: [
      program: "SELECT * FROM FavProducts",
      expected: Map.get(Chat.databases(), :FavProducts)
    ],
    select_id_products: [
      program: "SELECT id FROM Products",
      expected: %Chat.Database{
        headers: [:id],
        id: :Products,
        rows: [
          ["1"],
          ["2"],
          ["3"]
        ]
      }
    ],
    select_name_products: [
      program: "SELECT name FROM Products",
      expected: %Chat.Database{
        headers: [:name],
        id: :Products,
        rows: [
          ["Product 1"],
          ["Product 2"],
          ["Product 3"]
        ]
      }
    ],
    select_id_name_products: [
      program: "SELECT id, name FROM Products",
      expected: %Chat.Database{
        headers: [:id, :name],
        id: :Products,
        rows: [
          ["1", "Product 1"],
          ["2", "Product 2"],
          ["3", "Product 3"]
        ]
      }
    ],
    select_all_products_where: [
      program: "SELECT * FROM Products WHERE id == '2'",
      expected: Map.get(Chat.databases(), :Products) |> Database.where(:id, "2")
    ],
    select_all_brands_where: [
      program: "SELECT * FROM Brands WHERE id == '2'",
      expected: Map.get(Chat.databases(), :Brands) |> Database.where(:id, "2")
    ],
    select_columns_products_where: [
      program: "SELECT id, name FROM Products WHERE id == '2'",
      expected: %Chat.Database{
        headers: [:id, :name],
        id: :Products,
        rows: [
          ["2", "Product 2"]
        ]
      }
    ],
    select_columns_products_where_select_single_col: [
      program: "SELECT name FROM Products WHERE id == '2'",
      expected: %Chat.Database{
        headers: [:name],
        id: :Products,
        rows: [
          ["Product 2"]
        ]
      }
    ],
    select_columns_products_where_select_diff_cols: [
      program: "SELECT name, price FROM Products WHERE id == '2'",
      expected: %Chat.Database{
        headers: [:name, :price],
        id: :Products,
        rows: [
          ["Product 2", "13 dollars"]
        ]
      }
    ],
    select_columns_products_where_or: [
      program: "SELECT id, name FROM Products WHERE (id == '2' OR id == '3')",
      expected: %Chat.Database{
        headers: [:id, :name],
        id: :Products,
        rows: [
          ["2", "Product 2"],
          ["3", "Product 3"]
        ]
      }
    ],
    select_columns_products_where_or_and: [
      program: """
        SELECT id, name
        FROM Products
        WHERE (id == '2' AND name == 'Product 2')
      """,
      expected: %Chat.Database{
        headers: [:id, :name],
        id: :Products,
        rows: [
          ["2", "Product 2"]
        ]
      }
    ],
    select_columns_products_where_not_equals: [
      program: "SELECT id, name FROM Products WHERE id != '2'",
      expected: %Chat.Database{
        headers: [:id, :name],
        id: :Products,
        rows: [
          ["1", "Product 1"],
          ["3", "Product 3"]
        ]
      }
    ],
    basic_join_brands: [
      program: """
        SELECT *
        FROM Products p
        JOIN Brands b ON p.brand_id == b.id
      """,
      expected: %Chat.Database{
        headers: [:id, :name, :price, :brand_id, :api, :"b.name"],
        id: :Products,
        rows: [
          ["1", "Product 1", "12 dollars", "1", "acc", "Brand 1"],
          ["2", "Product 2", "13 dollars", "2", "acc", "Brand 2"],
          ["3", "Product 3", "14 dollars", "2", "akut", "Brand 2"]
        ]
      }
    ],
    reverse_join_brands: [
      program: """
        SELECT *
        FROM Products p
        JOIN Brands b ON b.id == p.brand_id
      """,
      expected: %Chat.Database{
        headers: [:id, :name, :price, :brand_id, :api, :"b.name"],
        id: :Products,
        rows: [
          ["1", "Product 1", "12 dollars", "1", "acc", "Brand 1"],
          ["2", "Product 2", "13 dollars", "2", "acc", "Brand 2"],
          ["3", "Product 3", "14 dollars", "2", "akut", "Brand 2"]
        ]
      }
    ],
    join_where_brands: [
      program: """
        SELECT *
        FROM Products p
        JOIN Brands b ON p.brand_id == b.id
        WHERE p.id == '2'
      """,
      expected: %Chat.Database{
        headers: [:id, :name, :price, :brand_id, :api, :"b.name"],
        id: :Products,
        rows: [
          ["2", "Product 2", "13 dollars", "2", "acc", "Brand 2"]
        ]
      }
    ],
    join_where_brands_inverse: [
      program: """
        SELECT *
        FROM Products p
        JOIN Brands b ON p.brand_id == b.id
        WHERE p.id != '2'
      """,
      expected: %Chat.Database{
        headers: [:id, :name, :price, :brand_id, :api, :"b.name"],
        id: :Products,
        rows: [
          ["1", "Product 1", "12 dollars", "1", "acc", "Brand 1"],
          ["3", "Product 3", "14 dollars", "2", "akut", "Brand 2"]
        ]
      }
    ],
    select_columns_join_where_brands_inverse: [
      program: """
        SELECT id, b.name
        FROM Products p
        JOIN Brands b ON p.brand_id == b.id
        WHERE p.id != '2'
      """,
      expected: %Chat.Database{
        headers: [:id, :"b.name"],
        id: :Products,
        rows: [
          ["1", "Brand 1"],
          ["3", "Brand 2"]
        ]
      }
    ],
    select_columns_join_where_brands_variable: [
      program: """
        col1 = id,
        col2 = 'b.name',
        SELECT [col1], [col2]
        FROM Products p
        JOIN Brands b ON p.brand_id == b.id
        WHERE p.id == '2'
      """,
      expected: %Chat.Database{
        headers: [:id, :"b.name"],
        id: :Products,
        rows: [
          ["2", "Brand 2"]
        ]
      }
    ],
    select_columns_join_where_brands_variable_inverse_order: [
      program: """
        col1 = id,
        col2 = 'b.name',
        SELECT [col2], [col1]
        FROM Products p
        JOIN Brands b ON p.brand_id == b.id
        WHERE p.id == '2'
      """,
      expected: %Chat.Database{
        headers: [:"b.name", :id],
        id: :Products,
        rows: [
          ["Brand 2", "2"]
        ]
      }
    ],
    select_columns_join_where_brands_to_text: [
      program: """
        col2 = 'b.name',
        prod_id = '2',
        res = SELECT [col2]
          FROM Products p
          JOIN Brands b ON p.brand_id == b.id
          WHERE p.id == [prod_id],
        TO_TEXT([res])
      """,
      expected: "Brand 2"
    ]
  ]

  Enum.each(tests, fn {name, data} ->
    @program Keyword.get(data, :program)
    @register Keyword.get(data, :register)
    @expected Keyword.get(data, :expected)

    test "#{name} language test" do
      ctx = Context.new(Chat.scenarios(), Chat.databases())
      prog = Parser.parse(@program) |> Interpreter.interpret()
      assert prog.(ctx, @register) == @expected
    end
  end)
end
