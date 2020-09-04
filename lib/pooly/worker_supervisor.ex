defmodule Pooly.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args)
  end

  def start_child(pid, opts \\ []) do
    DynamicSupervisor.start_child(pid, {Pooly.SampleWorker, opts})
  end

  def init(_args) do
    DynamicSupervisor.init(
      strategy: :one_for_one,
      max_restarts: 5,
      max_seconds: 5
    )
  end
end
