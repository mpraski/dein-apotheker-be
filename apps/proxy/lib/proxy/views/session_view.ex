defmodule Proxy.SessionView do
  use Proxy, :view

  def render("new.json", %{csrf_token: csrf_token}) do
    token = %{
      csrf_token: csrf_token
    }

    in_envelope(token)
  end
end
