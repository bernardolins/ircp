defmodule Alchevents.Registry.Topic do
  @registry_default_opts [
    keys: :unique,
    name: __MODULE__,
    partitions: System.schedulers_online()
  ]

  def child_spec(_) do
    Registry.child_spec(@registry_default_opts)
  end

  def register(channel, topic) do
    case Registry.register(__MODULE__, {channel, topic}, []) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
