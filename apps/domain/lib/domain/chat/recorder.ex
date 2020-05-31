defmodule Chat.Recorder do
  use GenServer

  # 1 minutes in milliseconds
  @tick_interval 60_000

  defmodule State do
    defstruct exporters: [], history: %{}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def record(token, context, answer) do
    GenServer.cast(__MODULE__, {:record, {token, context, answer}})
  end

  def add_exporter(exporter) when is_function(exporter, 1) do
    GenServer.cast(__MODULE__, {:add_exporter, exporter})
  end

  def sync do
    GenServer.cast(__MODULE__, :sync)
  end

  # Server

  @impl true
  def init(_) do
    tick()
    {:ok, %State{}}
  end

  @impl true
  def handle_cast(
        {
          :record,
          {token, context, answer}
        },
        %State{history: history} = state
      ) do
    history =
      history
      |> Map.update(
        token,
        default(context, answer),
        update(context, answer)
      )

    {:noreply, %State{state | history: history}}
  end

  @impl true
  def handle_cast(
        {:add_exporter, exporter},
        %State{exporters: exporters} = state
      ) do
    {:noreply, %State{state | exporters: [exporter | exporters]}}
  end

  @impl true
  def handle_info(
        :tick,
        %State{
          exporters: exporters,
          history: history
        } = state
      ) do
    history |> export_history(exporters)

    tick()

    {:noreply, %State{state | history: %{}}}
  end

  # Private

  defp tick, do: Process.send_after(self(), :tick, @tick_interval)

  defp default(context, answer) do
    with now <- Time.utc_now() do
      [{context, answer, now}]
    end
  end

  defp update(context, answer) do
    fn answers ->
      with now <- Time.utc_now() do
        [{context, answer, now} | answers]
      end
    end
  end

  defp export_history(history, []), do: history

  defp export_history(history, [e | rest]) do
    case e.(history) do
      :ok -> history |> export_history(rest)
      {:error, error} -> raise "Failed to export history: #{error}"
    end
  end
end
