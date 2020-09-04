defmodule Pooly do
  use Application

  def start(_type, _args) do
    pool_config = [size: 5]
    start_pool(pool_config)
  end

  def start_pool(pool_config), do: Pooly.Supervisor.start_link(pool_config)

  def checkout, do: Pooly.Server.checkout()

  def checkin(worker_pid), do: Pooly.Server.checkin(worker_pid)

  def status, do: Pooly.Server.status()
end
