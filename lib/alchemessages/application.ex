defmodule Alchemessages.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Alchemessages.Registry.Channel,
    ]

    opts = [strategy: :one_for_one, name: Alchemessages.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
