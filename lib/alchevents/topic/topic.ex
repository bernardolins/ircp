defmodule Alchevents.Topic do
  @moduledoc false

  use GenStage

  alias Alchevents.Topic.State

  def start_link(channel, topic), do: GenStage.start_link(__MODULE__, {channel, topic})

  def init({channel, topic}) do
    case Alchevents.Registry.Topic.register(channel, topic) do
      :ok -> {:producer, %State{}, dispatcher: GenStage.BroadcastDispatcher}
      {:error, reason} -> {:stop, reason}
    end
  end

  def publish(channel, topic, message) do
    case Alchevents.Registry.Topic.lookup(channel, topic) do
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
