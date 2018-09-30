defmodule IRCP.Client do
  def private_question(who, message) do
    GenStage.call(who, message)
  end

  def private_message(who, message) do
    GenStage.cast(who, message)
  end

  def join(who, channel_name) do
    with {:ok, {channel, _}} <- IRCP.Registry.Channel.lookup(channel_name),
         {:ok, _} <- GenStage.sync_subscribe(who, to: channel, channel_name: channel_name)
    do
      :ok
    else
      error -> error
    end
  end

  defmacro __using__(_) do
    quote do
      use GenStage
      require Logger

      def set_info(options), do: {:ok, options}
      def handle_join(_, info), do: {:ok, info}
      def handle_message(_, state), do: {:noreply, state}
      def handle_question(_, _, state), do: {:reply, :not_implemented, state}
      defoverridable [set_info: 1, handle_join: 2, handle_message: 2, handle_question: 3]

      def create(options \\ []) do
        GenStage.start_link(__MODULE__, options)
      end

      def init(options) do
        channel_names = options
        |> Keyword.get(:join_channels, [])
        |> List.wrap

        case set_info(options) do
          {:ok, info} ->
            {:consumer, info, subscribe_to: channel_names_to_pid(channel_names)}
          {:stop, _} = stop ->
            stop
          invalid ->
            {:stop, :bad_return_value}
        end
      end

      def handle_call(message, from, state) do
        case proteced_handle_question(message, from, state) do
          {:reply, reply, new_state} ->
            {:reply, reply, [], new_state}
          {:stop, _} = stop ->
            stop
          invalid_return ->
            {:stop, {:shutdown, :bad_return_value}, state}
        end
      end

      def handle_cast(message, state) do
        case proteced_handle_message(message, state) do
          {:noreply, state} ->
            {:noreply, [], state}
          {:stop, _} = stop ->
            stop
          _ ->
            {:stop, {:shutdown, :bad_return_value}, state}
        end
      end

      def handle_info(message, state) do
        case proteced_handle_message(message, state) do
          {:reply, reply, state} ->
            {:reply, reply, [], state}
          {:stop, _} = stop ->
            stop
          invalid_return ->
            {:stop, {:bad_return_value, invalid_return}}
        end
      end

      def handle_subscribe(:producer, opts, _, info) do
        channel_name = opts[:channel_name]
        case handle_join(channel_name, info) do
          {:ok, info} ->
            {:automatic, info}
          {:stop, _} = stop ->
            stop
          invalid_return ->
            {:stop, {:shutdown, :bad_return_value}, info}
        end
      end

      def handle_events(messages, _, state) do
        handle_messages(messages, state)
      end

      defp channel_names_to_pid([]), do: []
      defp channel_names_to_pid(channel_names) do
        Enum.reduce(channel_names, [], fn(channel_name, list) ->
          case IRCP.Registry.Channel.lookup(channel_name) do
            {:ok, {pid, _}} ->
              [{pid, channel_name: channel_name}|list]
            {:error, :not_found} ->
              Logger.warn("Channel not found: #{inspect channel_name}")
              list
          end
        end)
      end

      defp handle_messages([], state), do: {:noreply, [], state}
      defp handle_messages([message|messages], state) do
        case proteced_handle_message(message, state) do
          {:noreply, new_state} ->
            handle_messages(messages, new_state)
          _ ->
            {:stop, :normal, nil}
        end
      end

      defp proteced_handle_message(message, state) do
        try do
          handle_message(message, state)
        rescue
          FunctionClauseError ->
            {:noreply, state}
          CaseClauseError ->
            {:noreply, state}
        end
      end

      defp proteced_handle_question(message, from, state) do
        try do
          handle_question(message, from, state)
        rescue
          FunctionClauseError ->
            {:reply, :not_implemented, state}
          CaseClauseError ->
            {:reply, :not_implemented, state}
        end
      end

      defp assert_async_response({:noreply, new_state}), do: {:noreply, [], new_state}
      defp assert_async_response(invalid_return), do: call_stop(:bad_return_value, invalid_return, nil)

      defp assert_sync_response({:reply, reply, new_state}), do: {:reply, reply, [], new_state}
      defp assert_sync_response(invalid_return), do: call_stop(:bad_return_value, invalid_return, nil)

      defp call_stop(reason, message, new_state), do: {:stop, {reason, message}, new_state}
      defp call_stop(reason, message), do: {:stop, {reason, message}}
    end
  end
end
