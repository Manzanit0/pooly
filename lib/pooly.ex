defmodule Pooly do
  use Application

  def start(_type, _args) do
    pool_config = [
      [name: "Pool1", size: 2],
      [name: "Pool2", size: 3],
      [name: "Pool3", size: 5],
      [name: "Pool4", size: 4]
    ]

    Pooly.Supervisor.start_link(pool_config)
  end

  def checkout(pool_name), do: Pooly.Server.checkout(pool_name)

  def checkin(pool_name, worker_pid), do: Pooly.Server.checkin(pool_name, worker_pid)

  def status(pool_name), do: Pooly.Server.status(pool_name)
end
