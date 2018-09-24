defmodule Alchevents.Listener do
  def query(pid, message), do: GenStage.call(pid, message)

  defmacro __using__(_) do
    quote do
      use GenStage

      def start_link(channel, topic, options \\ []) do
        GenStage.start_link(__MODULE__, {channel, topic, options})
      end

      def init({channel, topic, options}) do
        with {:ok, initial_state} <- init(channel, topic, options),
             {:ok, {topic, []}} <- Alchevents.Registry.Topic.lookup(channel, topic)
        do
          {:consumer, initial_state, subscribe_to: [topic]}
        else
          {:error, :not_found} -> {:stop, :topic_not_found}
          unknown -> {:stop, :bad_return_value, unknown}
        end
      end

      def handle_events(messages, _, state) do
        handle_messages(messages, state)
      end

      defp handle_messages([], state), do: {:noreply, [], state}
      defp handle_messages([message|messages], state) do
        case handle_message(message, state) do
          {:noreply, new_state} ->
            handle_messages(messages, new_state)
          error ->
            {:stop, :bad_return_value, error}
        end
      end

      def handle_call(message, from, state) do
        case handle_query(message, from, state) do
          {:reply, reply, state} -> {:reply, reply, [], state}
          error -> {:stop, :bad_return_value, error}
        end
      end

      def init(_, _, _), do: {:ok, nil}
      def handle_message(_, state), do: {:noreply, state}
      def handle_query(_, _, state), do: {:reply, :not_implemented, state}
      defoverridable [init: 3, handle_message: 2, handle_query: 3]
    end
  end
end
