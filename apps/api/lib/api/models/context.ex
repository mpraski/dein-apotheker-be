defmodule Api.Context do
  @enforce_keys [:scenarios, :data]

  defstruct(
    scenarios: [],
    data: %{}
  )
end
