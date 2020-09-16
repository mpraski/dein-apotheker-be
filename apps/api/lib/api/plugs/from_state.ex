defmodule Api.Plugs.FromState do
  import Plug.Conn

  alias Plug.Conn
  alias Chat.State
  alias Chat.State.Process

  def init(_params) do
  end

  def call(
        %Conn{
          body_params: %{
            "state" => state,
            "answer" => answer
          }
        } = conn,
        _params
      ) do
    %Conn{conn | params: answer}
    |> assign(:state, parse_state(state))
    |> assign(:has_state?, true)
  end

  def call(%Conn{} = conn, _params), do: conn |> assign(:has_state?, false)

  defp parse_state(%{
         "question" => question,
         "scenarios" => scenarios,
         "processes" => processes,
         "variables" => variables
       }) do
    question = to_atom(question)
    scenarios = Enum.map(scenarios, &String.to_existing_atom/1)
    processes = Enum.map(processes, &parse_process/1)
    variables = parse_variables(variables)

    State.new(question, scenarios, processes, variables)
  end

  defp parse_process(%{
         "id" => id,
         "variables" => variables
       }) do
    Process.new(String.to_existing_atom(id), parse_variables(variables))
  end

  defp parse_variables(vars) do
    vars
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> Enum.into(Map.new())
  end

  defp to_atom(nil), do: nil

  defp to_atom(a) when is_binary(a), do: String.to_existing_atom(a)
end
