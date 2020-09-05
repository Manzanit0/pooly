defmodule Pooly.PoolSupervisor do
  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config)
  end

  def init(pool_config) do
    children = [
      worker(Pooly.PoolServer, [self(), pool_config])
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
