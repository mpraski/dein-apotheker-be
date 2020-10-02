defmodule LanguageTest do
  use ExUnit.Case
  doctest Chat.Language.Parser

  test "greets the world" do
    assert Domain.hello() == :world
  end
end
