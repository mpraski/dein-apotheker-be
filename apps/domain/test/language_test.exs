defmodule LanguageTest do
  use ExUnit.Case, async: true
  doctest Chat.Language.Parser

  alias Chat.Database
  alias Chat.Language.Parser
  alias Chat.Language.Context

  tests = [
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
          [1],
          [2],
          [3]
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
          [1, "Product 1"],
          [2, "Product 2"],
          [3, "Product 3"]
        ]
      }
    ]
  ]

  Enum.each(tests, fn {name, data} ->
    @program Keyword.get(data, :program)
    @register Keyword.get(data, :register)
    @expected Keyword.get(data, :expected)

    test "#{name} language test" do
      ctx = Context.new(Chat.scenarios(), Chat.databases())
      assert Parser.parse(@program).(ctx, @register) == @expected
    end
  end)
end
