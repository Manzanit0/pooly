defmodule Pooly.Supervisor do
  use Supervisor

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def init(pools_config) do
    children = [
      supervisor(Pooly.PoolsSupervisor, []),
      worker(Pooly.Server, [pools_config])
    ]

    opts = [
      # If the server crashes, the state of the worker supervisor would be
      # inconsistent, so kill both.
      strategy: :one_for_all,
      max_restarts: 1,
      max_time: 3600
    ]

    Supervisor.init(children, opts)
  end
end
