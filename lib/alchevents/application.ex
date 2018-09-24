defmodule Alchevents.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Alchevents.Registry.Channel,
    ]

    opts = [strategy: :one_for_one, name: Alchevents.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
