defmodule Pooly.Server do
  use GenServer

  defmodule State do
    defstruct [:sup, :size, :worker_sup, :workers, :monitors]
  end

  #######
  # API #
  #######

  def start_link(sup, pool_config) do
    GenServer.start_link(__MODULE__, [sup, pool_config], name: __MODULE__)
  end

  def checkout do
    GenServer.call(__MODULE__, :checkout)
  end

  def checkin(worker_pid) do
    GenServer.cast(__MODULE__, {:checkin, worker_pid})
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  #############
  # Callbacks #
  #############

  @impl true
  def init([sup, pool_config]) when is_pid(sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{sup: sup, monitors: monitors})
  end

  def init([{:size, size} | rest], state), do: init(rest, %{state | size: size})

  def init([_ | rest], state), do: init(rest, state)

  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  @impl true
  def handle_info(:start_worker_supervisor, %State{} = state) do
    # Since the Server is in charge of spinning up the WorkerSupervisor, and we
    # don't want the upstream supervisor restarting it, make it temporary.
    supervisor_spec = Supervisor.child_spec({Pooly.WorkerSupervisor, []}, restart: :temporary)
    {:ok, worker_sup} = Supervisor.start_child(state.sup, supervisor_spec)

    workers = prepopulate(state.size, worker_sup)

    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, _}, %State{} = state) do
    case :ets.match(state.monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(state.monitors, pid)
        new_state = %{state | workers: [pid | state.workers]}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, %State{} = state) do
    case :ets.lookup(state.monitors, pid) do
      [[pid, ref]] ->
        true = Process.demonitor(ref)
        true = :ets.delete(state.monitors, pid)
        new_state = %{state | workers: [new_worker(state.sup) | state.workers]}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:status, _from, %State{} = state) do
    {:reply, {length(state.workers), :ets.info(state.monitors, :size)}, state}
  end

  @impl true
  def handle_call(:checkout, {from_pid, _ref}, %State{} = state) do
    case state.workers do
      [worker | rest] ->
        # We want to monitor the client process because in case it crashes, we
        # might just want to get our worker back in the pool.
        ref = Process.monitor(from_pid)
        true = :ets.insert(state.monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] ->
        {:reply, :noproc, state}
    end
  end

  @impl true
  def handle_cast({:checkin, worker_pid}, %State{} = state) do
    case :ets.lookup(state.monitors, worker_pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(state.monitors, pid)
        {:noreply, %{state | workers: [pid | state.workers]}}

      [] ->
        {:noreply, state}
    end
  end

  defp prepopulate(size, sup), do: prepopulate(size, sup, [])

  defp prepopulate(size, _sup, workers) when size < 1, do: workers

  defp prepopulate(size, sup, workers) do
    prepopulate(size - 1, sup, [new_worker(sup) | workers])
  end

  defp new_worker(sup) do
    {:ok, worker} = Pooly.WorkerSupervisor.start_child(sup, [])
    worker
  end
end
