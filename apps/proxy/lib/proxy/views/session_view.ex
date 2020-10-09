defmodule Proxy.SessionView do
  use Proxy, :view

  def render("new.json", %{csrf_token: csrf_token}) do
    %{
      csrf_token: csrf_token
    }
  end
end
