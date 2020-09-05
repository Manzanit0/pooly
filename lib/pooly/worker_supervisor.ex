defmodule Pooly.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(pool_server) do
    DynamicSupervisor.start_link(__MODULE__, pool_server)
  end

  def start_child(pid, opts \\ []) do
    DynamicSupervisor.start_child(pid, {Pooly.SampleWorker, opts})
  end

  def init(pool_server) do
    # If the pool server goes down... so should the the supervisor
    Process.link(pool_server)

    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 5
    )
  end
end
