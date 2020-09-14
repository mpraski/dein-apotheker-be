defmodule Api.ChatHelpers do
  def id({_, question, _}), do: question

  def input({[], _, _}) do
    %{
      type: :end
    }
  end

  def messages(_), do: nil
end
