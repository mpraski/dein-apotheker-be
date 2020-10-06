defmodule Account do
  @moduledoc """
  Documentation for `Account`.
  """

  alias Account.User

  def get(id) do
    {:ok, User.new(id)}
  end

  def login(email, password) do
    {:ok, User.new()}
  end
end
