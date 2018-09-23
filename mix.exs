defmodule Alchevents.MixProject do
  use Mix.Project

  def project do
    [
      app: :alchevents,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Alchevents.Application, []}
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 0.14.0"},
    ]
  end
end
