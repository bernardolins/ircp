defmodule Alchemessages.Channel do
  @moduledoc false

  use GenStage

  alias Alchemessages.Channel.State

  def start_link(channel_name, opts \\ []), do: GenStage.start_link(__MODULE__, {channel_name, opts})

  def init({channel_name, opts}) do
    case Alchemessages.Registry.Channel.register(channel_name, opts) do
      :ok -> {:producer, State.new(), dispatcher: GenStage.BroadcastDispatcher}
      {:error, reason} -> {:stop, reason}
    end
  end

  def publish(channel_name, message) do
    case Alchemessages.Registry.Channel.lookup(channel_name) do
      {:ok, {pid, _}} -> GenStage.cast(pid, {:publish, message})
      {:error, :not_found} -> {:error, :topic_not_found}
    end
  end

  def handle_cast({:publish, message}, %State{} = state) do
    store_message(state, message)
  end

  def handle_demand(incoming_demand, %State{} = state) do
    change_demand_by(state, incoming_demand)
  end

  defp store_message(%State{} = state, message) do
    state
    |> State.store_event(message)
    |> dispatch_events
  end

  defp change_demand_by(%State{} = state, demand_delta) when is_integer(demand_delta) do
    state
    |> State.update_demand(demand_delta)
    |> dispatch_events
  end

  defp dispatch_events(state, event_list \\ [])
  defp dispatch_events(%State{demand: 0} = state, event_list), do: {:noreply, event_list, state}
  defp dispatch_events(%State{} = state, event_list) do
    case State.next_event(state) do
      {:empty, new_state} -> {:noreply, event_list, new_state}
      {:ok, message, new_state} ->
        updated_state = State.update_demand(new_state, -1)
        dispatch_events(updated_state, [message|event_list])
    end
  end
end
