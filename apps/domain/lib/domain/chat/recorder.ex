defmodule Chat.Recorder do
  use GenServer

  # 1 minutes in milliseconds
  @tick_interval 60_000

  defmodule State do
    defstruct exporters: [], history: %{}
  end

  def start_link(exporters) do
    GenServer.start_link(__MODULE__, exporters, name: __MODULE__)
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

  def pid do
    GenServer.call(__MODULE__, :pid)
  end

  # Server

  @impl true
  def init(exporters) do
    tick()
    {:ok, %State{exporters: exporters}}
  end

  @impl true
  def handle_call(:pid, _from, state), do: {:reply, self(), state}

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
    with now <- DateTime.utc_now() do
      [{context, answer, now}]
    end
  end

  defp update(context, answer) do
    fn answers ->
      with now <- DateTime.utc_now() do
        [{context, answer, now} | answers]
      end
    end
  end

  defp export_history(history, exporters) do
    history |> Enum.reverse() |> export(exporters)
  end

  defp export(history, exporters) do
    results =
      exporters
      |> Enum.map(&fn -> &1.(history) end)
      |> Enum.map(&Task.async/1)
      |> Enum.map(&Task.await/1)
      |> Enum.filter(fn
        :ok -> false
        _ -> true
      end)

    case results do
      [] -> :ok
      [{:error, e} | _] -> raise "Failed to export history: #{e}"
    end
  end
end
