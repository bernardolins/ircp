defmodule Alchevents.Topic do
  @moduledoc false

  use GenStage

  alias Alchevents.Topic.State

  def start_link(channel, topic), do: GenStage.start_link(__MODULE__, {channel, topic})

  def init({channel, topic}) do
    :ok = Alchevents.Registry.Topic.register(channel, topic)
    {:producer, %State{}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def publish(channel, topic, event) do
    {:ok, {pid, _}} = Alchevents.Registry.Topic.lookup(channel, topic)
    GenStage.cast(pid, {:publish, event})
  end

  def handle_cast({:publish, event}, %State{} = state) do
    store_event(state, event)
  end

  def handle_demand(incoming_demand, %State{} = state) do
    change_demand_by(state, incoming_demand)
  end

  defp store_event(%State{} = state, event) do
    state
    |> State.store_event(event)
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
      {:ok, event, new_state} -> dispatch_events(new_state, [event|event_list])
    end
  end
end
