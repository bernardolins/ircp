defmodule Alchemessages.Registry.Channel do
  @registry_default_opts [
    keys: :unique,
    name: __MODULE__,
    partitions: System.schedulers_online()
  ]

  def child_spec(_) do
    Registry.child_spec(@registry_default_opts)
  end

  def register(channel_name) do
    case Registry.register(__MODULE__, channel_name, []) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def lookup(channel_name) do
    case Registry.lookup(__MODULE__, channel_name) do
      [] -> {:error, :not_found}
      [{pid, opts}] -> {:ok, {pid, opts}}
    end
  end
end
