defmodule Api.Plugs.FromContext do
  import Plug.Conn

  alias Plug.Conn

  def init(_params) do
  end

  def call(
        %Conn{
          body_params: %{
            "context" => %{
              "data" => data,
              "question" => question,
              "scenarios" => scenarios
            },
            "data" => data
          }
        } = conn,
        _params
      ) do
    %Conn{conn | body_params: data}
    |> assign(:context, {scenarios, question, data})
    |> assign(:has_context?, true)
  end

  def call(%Conn{} = conn, _params), do: conn |> assign(:has_context?, false)
end
