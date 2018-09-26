defmodule IRCP.Channel do
  @moduledoc false

  use GenStage

  alias IRCP.Channel.State

  def create(channel_name, opts \\ []), do: GenStage.start_link(__MODULE__, {channel_name, opts})

  def init({channel_name, opts}) do
    case IRCP.Registry.Channel.register(channel_name, opts) do
      :ok -> {:producer, State.new(), dispatcher: GenStage.BroadcastDispatcher}
      {:error, reason} -> {:stop, reason}
    end
  end

  def publish(channel_name, message) do
    case IRCP.Registry.Channel.lookup(channel_name) do
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
    |> State.buffer_message(message)
    |> dispatch_messages
  end

  defp change_demand_by(%State{} = state, demand_delta) when is_integer(demand_delta) do
    state
    |> State.update_demand(demand_delta)
    |> dispatch_messages
  end

  defp dispatch_messages(state, message_list \\ [])
  defp dispatch_messages(%State{demand: 0} = state, message_list), do: {:noreply, message_list, state}
  defp dispatch_messages(%State{} = state, message_list) do
    case State.next_message(state) do
      {:empty, new_state} -> {:noreply, message_list, new_state}
      {:ok, message, new_state} ->
        updated_state = State.update_demand(new_state, -1)
        dispatch_messages(updated_state, [message|message_list])
    end
  end
end
