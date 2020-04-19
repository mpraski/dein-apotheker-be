defmodule Mix.Tasks.Validate do
    use Mix.Task

    require Chat.Loader
  
    @shortdoc "Validate the scenarios"
    def run(_) do
        Chat.Loader.load_scenarios(Path.join(File.cwd!(), "../../scenarios"))
    end
  end
  