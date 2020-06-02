defmodule Api.Plugs.RequireToken do
  import Plug.Conn

  alias Plug.Conn
  alias Api.ErrorView
  alias Phoenix.Controller

  def init(_params) do
  end

  def call(%Conn{req_headers: headers} = conn, _params) do
    predicate = fn
      {"token", token} ->
        case UUID.info(token) do
          {:ok, _} -> true
          {:error, _} -> false
        end

      _ ->
        false
    end

    with found <- headers |> Enum.find(predicate) do
      case found do
        {"token", token} ->
          conn
          |> assign(:token, token)
          |> assign(:has_token?, true)

        nil ->
          conn
          |> put_status(400)
          |> Controller.put_view(ErrorView)
          |> Controller.render("missing_token.json")
      end
    end
  end
end
