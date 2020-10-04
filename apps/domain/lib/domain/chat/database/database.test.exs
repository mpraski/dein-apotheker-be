defmodule Chat.Database.Test do
  use ExUnit.Case, async: true
  doctest Chat.Database

  alias Chat.Database
  alias Chat.Language.Memory

  test "where column exists" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: [["2", "Product 2", "13 dollars", "2", "acc"]]
    }

    assert Database.where(prods, :id, "2") == expected
  end

  test "where column doesn't exists" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)

    catch_error(Database.where(prods, :ids, "2"))
  end

  test "union of two databases" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "2")
    db2 = Database.where(prods, :id, "3")

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: [
        ["2", "Product 2", "13 dollars", "2", "acc"],
        ["3", "Product 3", "14 dollars", "2", "akut"]
      ]
    }

    assert Database.union(db1, db2) == expected
  end

  test "union of two databases, one empty" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "2")
    db2 = Database.where(prods, :id, "30")

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: [
        ["2", "Product 2", "13 dollars", "2", "acc"]
      ]
    }

    assert Database.union(db1, db2) == expected
  end

  test "union of two databases, other empty" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "20")
    db2 = Database.where(prods, :id, "3")

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: [
        ["3", "Product 3", "14 dollars", "2", "akut"]
      ]
    }

    assert Database.union(db1, db2) == expected
  end

  test "union of two databases, both empty" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "20")
    db2 = Database.where(prods, :id, "30")

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: []
    }

    assert Database.union(db1, db2) == expected
  end

  test "intersection of two databases" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "2")

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: [
        ["2", "Product 2", "13 dollars", "2", "acc"]
      ]
    }

    assert Database.intersection(prods, db1) == expected
  end

  test "intersection of two databases, other case" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "3")

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: [
        ["3", "Product 3", "14 dollars", "2", "akut"]
      ]
    }

    assert Database.intersection(db1, prods) == expected
  end

  test "intersection of two databases, one empty" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "20")

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: []
    }

    assert Database.intersection(prods, db1) == expected
  end

  test "intersection of two databases, other empty" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "30")

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api],
      id: :Products,
      rows: []
    }

    assert Database.intersection(db1, prods) == expected
  end

  test "join of two databases" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    {:ok, brands} = Chat.databases() |> Map.fetch(:Brands)

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api, :"b.name"],
      id: :Products,
      rows: [
        ["1", "Product 1", "12 dollars", "1", "acc", "Brand 1"],
        ["2", "Product 2", "13 dollars", "2", "acc", "Brand 2"],
        ["3", "Product 3", "14 dollars", "2", "akut", "Brand 2"]
      ]
    }

    assert Database.join(prods, brands, :brand_id, :id, :b, &Kernel.==/2) == expected
  end

  test "join of two databases, not equals" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    {:ok, brands} = Chat.databases() |> Map.fetch(:Brands)

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api, :"b.name"],
      id: :Products,
      rows: [
        ["1", "Product 1", "12 dollars", "1", "acc", "Brand 2"],
        ["2", "Product 2", "13 dollars", "2", "acc", "Brand 1"],
        ["3", "Product 3", "14 dollars", "2", "akut", "Brand 1"]
      ]
    }

    assert Database.join(prods, brands, :brand_id, :id, :b, &Kernel.!=/2) == expected
  end

  test "failed join of two databases" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    {:ok, brands} = Chat.databases() |> Map.fetch(:Brands)

    expected = %Chat.Database{
      headers: [:id, :name, :price, :brand_id, :api, :"b.id"],
      id: :Products,
      rows: []
    }

    assert Database.join(prods, brands, :brand_id, :name, :b, &Kernel.==/2) == expected
  end

  test "width of a database" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)

    assert Database.width(prods) == 5
  end

  test "height of a database" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)

    assert Database.height(prods) == 3
  end

  test "header index of a database" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)

    assert Database.header_index(prods, :id) == 0
    assert Database.header_index(prods, :name) == 1
    catch_error(Database.header_index(prods, :whut))
  end

  test "database to list" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)

    list = [
      [id: "1", name: "Product 1", price: "12 dollars", brand_id: "1", api: "acc"],
      [id: "2", name: "Product 2", price: "13 dollars", brand_id: "2", api: "acc"],
      [id: "3", name: "Product 3", price: "14 dollars", brand_id: "2", api: "akut"]
    ]

    assert Enum.to_list(prods) == list
  end

  test "database from list" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)

    list = [
      [id: "1", name: "Product 1", price: "12 dollars", brand_id: "1", api: "acc"],
      [id: "2", name: "Product 2", price: "13 dollars", brand_id: "2", api: "acc"],
      [id: "3", name: "Product 3", price: "14 dollars", brand_id: "2", api: "akut"]
    ]

    assert list |> Enum.into(Database.new(:Products)) == prods
  end

  test "database to string" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    db1 = Database.where(prods, :id, "1")

    expected = "1, Product 1, 12 dollars, 1, acc"

    assert to_string(db1) == expected
  end

  test "database as memory" do
    {:ok, prods} = Chat.databases() |> Map.fetch(:Products)
    {:ok, rows} = Memory.load(prods, :id)

    expected = ["1", "2", "3"]

    assert rows == expected
  end
end
