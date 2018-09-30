defmodule IRCP.Support.ValidationClient do
  use IRCP.Client

  def set_info(options) do
    case options do
      [invalid_return: true] ->
        {:invalid, :invalid_return}
      [pid: test_process_id] ->
        send(test_process_id, {:set_info_called, self() })
        {:ok, test_process_id}
      [pid: test_process_id, join_channels: _] ->
        {:ok, test_process_id}
      _ ->
        {:ok, nil}
    end
  end

  def handle_join(channel, test_process_id) do
    case channel do
      :invalid_return ->
        {:invalid, :invalid_return}
      :test_callback ->
        send(test_process_id, {:handle_join_called, channel, self()})
        {:ok, test_process_id}
      _ ->
        {:ok, test_process_id}
    end
  end

  def handle_message(message, test_process_id) do
    case message do
      :invalid_return ->
        {:invalid, :invalid_return}
      :test_callback ->
        send(test_process_id, {:handle_message_called, self()})
        {:noreply, test_process_id}
      _ ->
        {:noreply, test_process_id}
    end
  end

  def handle_question(message, _, test_process_id) do
    case message do
      :invalid_return ->
        {:invalid, :invalid_response, :invalid_return}
      :test_callback ->
        {:reply, :handle_question_called, test_process_id}
    end
  end
end
