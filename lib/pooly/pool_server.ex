defmodule Pooly.PoolServer do
  use GenServer

  defmodule State do
    defstruct [:pool_sup, :size, :worker_sup, :workers, :monitors, :name]
  end

  #######
  # API #
  #######

  def start_link(pool_sup, pool_config) do
    GenServer.start_link(__MODULE__, [pool_sup, pool_config], name: name(pool_config[:name]))
  end

  def checkout(pool_name) do
    GenServer.call(name(pool_name), :checkout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.cast(name(pool_name), {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(name(pool_name), :status)
  end

  #############
  # Callbacks #
  #############

  @impl true
  def init([pool_sup, pool_config]) when is_pid(pool_sup) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    init(pool_config, %State{pool_sup: pool_sup, monitors: monitors})
  end

  def init([{:size, size} | rest], state), do: init(rest, %{state | size: size})

  def init([{:name, name} | rest], state), do: init(rest, %{state | name: name})

  def init([_ | rest], state), do: init(rest, state)

  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  @impl true
  def handle_info(:start_worker_supervisor, %State{} = state) do
    # Since the Server is in charge of spinning up the WorkerSupervisor, and we
    # don't want the upstream supervisor restarting it, make it temporary.
    opts = [id: state.name <> "WorkerSupervisor", restart: :temporary, shutdown: 10000]

    supervisor_spec = Supervisor.child_spec({Pooly.WorkerSupervisor, self()}, opts)
    {:ok, worker_sup} = Supervisor.start_child(state.pool_sup, supervisor_spec)

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

  # If the worker supervisor goes down, so does the server
  @impl true
  def handle_info({:EXIT, worker_sup, reason}, %State{worker_sup: worker_sup} = state) do
    {:stop, reason, state}
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, %State{} = state) do
    case :ets.lookup(state.monitors, pid) do
      [[pid, ref]] ->
        true = Process.demonitor(ref)
        true = :ets.delete(state.monitors, pid)
        new_state = %{state | workers: [new_worker(state.pool_sup) | state.workers]}
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

  @impl true
  def terminate(_reason, _state), do: :ok

  defp prepopulate(size, pool_sup), do: prepopulate(size, pool_sup, [])

  defp prepopulate(size, _sup, workers) when size < 1, do: workers

  defp prepopulate(size, pool_sup, workers) do
    prepopulate(size - 1, pool_sup, [new_worker(pool_sup) | workers])
  end

  defp new_worker(pool_sup) do
    {:ok, worker} = Pooly.WorkerSupervisor.start_child(pool_sup, [])
    worker
  end

  defp name(pool_name), do: :"#{pool_name}Server"
end
