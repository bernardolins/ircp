defmodule IRCP.Client do
  def ask(who, message), do: GenStage.call(who, message)
  def tell(who, message), do: GenStage.cast(who, message)
  def join(client, channel_name) do
    case IRCP.Registry.Channel.lookup(channel_name) do
      {:ok, {channel, _}} ->
        GenStage.async_subscribe(client, to: channel)
        :ok
      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  defmacro __using__(_) do
    quote do
      use GenStage
      require Logger

      def start_link(options \\ []) do
        GenStage.start_link(__MODULE__, options)
      end

      def init(options) do
        channel_names = options
        |> Keyword.get(:join_channels, [])
        |> List.wrap

        channel_list = get_channel_list(channel_names)

        with {:ok, info} <- set_info(options),
             {:ok, info} <- join_list(channel_names, info)
        do
          {:consumer, info, subscribe_to: channel_list}
        else
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

      def handle_info(message, state) do
        case proteced_handle_message(message, state) do
          {:noreply, state} ->
            {:noreply, [], state}
          error ->
            {:stop, :bad_return_value, error}
        end
      end

      defp get_channel_list(channel_names) do
        Enum.reduce(channel_names, [], fn(channel_name, list) ->
          case IRCP.Registry.Channel.lookup(channel_name) do
            {:ok, {pid, _}} ->
              [{pid, channel: channel_name}|list]
            {:error, :not_found} ->
              Logger.warn("Channel not found: #{inspect channel_name}")
              list
          end
        end)
      end

      def handle_subscribe(:producer, opts, _, info) do
        channel_name = opts[:channel_name]
        case handle_join(channel_name, info) do
          {:ok, info} -> join_list(channel_list, info)
          error -> {:stop, :bad_return_value, error}
        end
        {:automatic, info}
      end

      defp join_list([], info), do: {:ok, info}
      defp join_list([channel_name|channel_list], info) do
        case handle_join(channel_name, info) do
          {:ok, info} -> join_list(channel_list, info)
          error -> {:stop, :bad_return_value, error}
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

      def set_info(options), do: {:ok, options}
      def handle_join(_, info), do: {:ok, info}
      def handle_message(_, state), do: {:noreply, state}
      def handle_question(_, _, state), do: {:reply, :not_implemented, state}
      defoverridable [set_info: 1, handle_join: 2, handle_message: 2, handle_question: 3]
    end
  end
end
