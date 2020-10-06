defmodule Auth.Guardian do
  use Guardian, otp_app: :auth

  alias Account.User

  def subject_for_token(%User{id: id}, _claims) do
    {:ok, id}
  end

  def subject_for_token(_, _) do
    {:error, :no_user_provided}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    kind = claims["kind"]

    case kind do
      "guest" -> {:ok, User.new(id)}
      "user" -> Account.get(id)
      _ -> {:error, :unrecognized_kind}
    end
  end
end
