defmodule IRCP.MixProject do
  use Mix.Project

  def project do
    [
      app: :ircp,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {IRCP.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp preferred_cli_env() do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end

  defp deps do
    [
      {:gen_stage, "~> 0.14.0"},
      {:excoveralls, "~> 0.10.1", only: :test},
    ]
  end
end
