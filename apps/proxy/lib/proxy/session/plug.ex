defmodule Proxy.Session.Plug do
  import Plug.Conn

  alias Plug.Conn
  alias Proxy.Session.Store
  alias Auth.Issuer
  alias Account.User
  alias Chat.Driver

  def init(_params) do
  end

  def call(%Conn{} = conn, _params) do
    token = conn |> get_session(:token)

    state = fn -> Driver.initial({Chat.scenarios(), Chat.databases()}) end

    case Guardian.decode_and_verify(__MODULE__, token) do
      {:ok, claims} ->
        {:ok, session} = Store.fetch_or_store(claims["sub"], state)

        conn |> assign(:session, session)

      {:error, _reason} ->
        {:ok, token, %User{id: id}} = Issuer.guest()

        {:ok, session} = Store.fetch_or_store(id, state)

        conn
        |> put_session(:token, token)
        |> assign(:session, session)
    end
  end
end
