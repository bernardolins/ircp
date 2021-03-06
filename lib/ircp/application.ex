defmodule IRCP.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      IRCP.Registry.Channel,
    ]

    opts = [strategy: :one_for_one, name: IRCP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
