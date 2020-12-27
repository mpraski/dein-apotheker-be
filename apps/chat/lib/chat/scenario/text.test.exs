defmodule Chat.Scenario.Text.Test do
  use ExUnit.Case, async: true
  doctest Chat.Scenario.Text

  alias Chat.Scenario.Text

  test "empty text" do
    t = Text.new("")

    assert render(t) == ""
  end

  test "some text" do
    t = Text.new("some text")

    assert render(t) == "some text"
  end


  test "some text with basic expression" do
    t = Text.new("some text {l = LIST(a, b, c, 1); TO_TEXT([l])}")

    assert render(t) == "some text a b c 1"
  end

  test "some text with memory expression" do
    t = Text.new("some text {[a]}")

    assert render(t, %{a: 4}) == "some text 4"
  end

  test "some text with db expression" do
    t = Text.new("some text {SELECT name FROM Products WHERE id == '2'}")

    assert render(t) == "some text Product 2"
  end

  test "some text with db expression, two columns" do
    t = Text.new("some text {SELECT id, name FROM Products WHERE id == '2'}")

    assert render(t) == "some text 2, Product 2"
  end

  defp render(t, i \\ nil) do
    Text.render(t, i)
  end
end
