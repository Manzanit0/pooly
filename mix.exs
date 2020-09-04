defmodule Pooly.MixProject do
  use Mix.Project

  def project do
    [
      app: :pooly,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Pooly, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end
end
