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

  def lookup(channel, topic) do
    case Registry.lookup(__MODULE__, {channel, topic}) do
      [] -> {:error, :not_found}
      [{pid, opts}] -> {:ok, {pid, opts}}
    end
  end
end
