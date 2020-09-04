defmodule Pooly.Supervisor do
  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config)
  end

  def init(pool_config) do
    children = [
      worker(Pooly.Server, [self(), pool_config])
    ]

    opts = [
      # If the server crashes, the state of the worker supervisor would be
      # inconsistent, so kill both.
      strategy: :one_for_all
    ]

    Supervisor.init(children, opts)
  end
end
