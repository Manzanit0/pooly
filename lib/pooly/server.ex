defmodule Pooly.Server do
  use GenServer

  defmodule State do
    defstruct [:sup, :size, :worker_sup, :workers, :monitors]
  end

  #######
  # API #
  #######

  def start_link(pools_config) do
    GenServer.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def checkout(pool_name) do
    GenServer.call(:"#{pool_name}Server", :checkout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.cast(:"#{pool_name}Server", {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(:"#{pool_name}Server", :status)
  end

  #############
  # Callbacks #
  #############

  @impl true
  def init(pools_config) do
    Enum.each(pools_config, fn x -> send(self(), {:start_pool, x}) end)
    {:ok, pools_config}
  end

  @impl true
  def handle_info({:start_pool, pool_config}, state) do
    {:ok, _pool_sup} = Supervisor.start_child(Pooly.PoolsSupervisor, supervisor_spec(pool_config))
    {:noreply, state}
  end

  def supervisor_spec(pool_config) do
    opts = [id: :"#{pool_config[:name]}Supervisor"]
    Supervisor.child_spec({Pooly.PoolSupervisor, pool_config}, opts)
  end
end
