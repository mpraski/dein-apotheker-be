defmodule Chat.Initializer do
  require Chat.Loader
  alias Chat.Loader

  defmacro __using__(_) do
    scenarios =
      File.cwd!()
      |> Path.join(Application.get_env(:domain, :scenario_path))
      |> Loader.load_scenarios()

    for {k, v} <- scenarios do
      quote do
        def scenario(unquote(k)), do: unquote(Macro.escape(v))

        unquote do
          for {q, c} <- v.questions do
            quote do
              def question(unquote(k), unquote(q)), do: unquote(Macro.escape(c))
            end
          end
        end

        unquote do
          for {p, c} <- v.products do
            quote do
              def product(unquote(k), unquote(p)), do: unquote(Macro.escape(c))
            end
          end
        end
      end
    end
  end
end
