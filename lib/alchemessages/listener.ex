defmodule Alchemessages.Listener do
  def ask(who, message), do: GenStage.call(who, message)
  def tell(who, message), do: GenStage.cast(who, message)

  defmacro __using__(_) do
    quote do
      use GenStage

      def start_link(channel_name, options \\ []) do
        GenStage.start_link(__MODULE__, {channel_name, options})
      end

      def init({channel_name, options}) do
        with {:ok, initial_state} <- join(channel_name, options),
             {:ok, {channel, []}} <- Alchemessages.Registry.Channel.lookup(channel_name)
        do
          {:consumer, initial_state, subscribe_to: [channel]}
        else
          {:error, :not_found} -> {:stop, :channel_not_found}
          unknown -> {:stop, :bad_return_value, unknown}
        end
      end

      def handle_events(messages, _, state) do
        handle_messages(messages, state)
      end

      def handle_call(message, from, state) do
        case proteced_handle_question(message, from, state) do
          {:reply, reply, state} ->
            {:reply, reply, [], state}
          error ->
            {:stop, :bad_return_value, error}
        end
      end

      def handle_cast(message, state) do
        case proteced_handle_message(message, state) do
          {:noreply, state} ->
            {:noreply, [], state}
          error ->
            {:stop, :bad_return_value, error}
        end
      end

      defp handle_messages([], state), do: {:noreply, [], state}
      defp handle_messages([message|messages], state) do
        case proteced_handle_message(message, state) do
          {:noreply, new_state} ->
            handle_messages(messages, new_state)
          error ->
            {:stop, :bad_return_value, error}
        end
      end

      defp proteced_handle_message(message, state) do
        try do
          handle_message(message, state)
        rescue
          FunctionClauseError -> {:noreply, state}
        end
      end

      defp proteced_handle_question(message, from, state) do
        try do
          handle_question(message, from, state)
        rescue
          FunctionClauseError -> {:reply, :not_implemented, state}
        end
      end

      def join(_, _, _), do: {:ok, nil}
      def handle_message(_, state), do: {:noreply, state}
      def handle_question(_, _, state), do: {:reply, :not_implemented, state}
      defoverridable [join: 3, handle_message: 2, handle_question: 3]
    end
  end
end
