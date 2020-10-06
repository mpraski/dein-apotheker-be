defmodule Auth.Issuer do
  alias Auth.Guardian
  alias Account.User

  @user_claim %{kind: "user"}
  @guest_claim %{kind: "guest"}

  def guest do
    for_user(User.new(), @guest_claim)
  end

  def login(email, password) do
    case Account.login(email, password) do
      {:ok, user} -> for_user(user, @user_claim)
      {:error, reason} -> {:error, reason}
    end
  end

  def refresh(token) do
    {:ok, _old, {token, _claims}} = Guardian.refresh(token)
    {:ok, token}
  end

  def user_id(token) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} -> {:ok, claims["sub"]}
      {:error, reason} -> {:error, reason}
    end
  end

  defp for_user(%User{} = user, claim) do
    {:ok, token, _} = Guardian.encode_and_sign(user, claim, ttl: ttl())
    {:ok, token, user}
  end

  defp ttl, do: {1, :hour}
end
