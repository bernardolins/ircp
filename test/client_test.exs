defmodule IRCP.ClientTest do
  use ExUnit.Case
  alias IRCP.Support.ValidationClient

  describe "callback set_info" do
    test "aborts creation when the return value is not {:ok, _}" do
      Process.flag(:trap_exit, true)
      assert {:error, :bad_return_value} = ValidationClient.create(invalid_return: true)
      assert_receive {:EXIT, _, :bad_return_value}
    end

    test "is called when a client is created with the argument passed to create" do
      assert {:ok, pid} = ValidationClient.create(pid: self())
      assert_receive {:set_info_called, pid}
    end
  end

  describe "callback handle_join" do
    test "is called when a client joins a channel" do
      IRCP.Channel.create(:test_callback)
      {:ok, pid} = ValidationClient.create(pid: self())
      IRCP.Client.join(pid, :test_callback)
      assert_receive {:handle_join_called, :test_callback, pid}
    end

    test "is called when a client joins a channel on it's creation" do
      IRCP.Channel.create(:test_callback)
      {:ok, pid} = ValidationClient.create(pid: self(), join_channels: [:test_callback])
      assert_receive {:handle_join_called, :test_callback, ^pid}
    end

    test "exits process when the return value is not {:ok, _}" do
      Process.flag(:trap_exit, true)
      IRCP.Channel.create(:invalid_return)
      {:ok, pid} = ValidationClient.create()
      catch_exit IRCP.Client.join(pid, :invalid_return)
      assert_receive {:EXIT, pid, {:shutdown, :bad_return_value}}
    end
  end

  describe "callback handle_message" do
    test "is called when a client receive a private message" do
      {:ok, pid} = ValidationClient.create(pid: self())
      IRCP.Client.private_message(pid, :test_callback)
      assert_receive {:handle_message_called, pid}
    end

    test "is called when a client receive a message from the channel" do
      IRCP.Channel.create(:channel)
      {:ok, pid} = ValidationClient.create(pid: self())
      IRCP.Client.join(pid, :channel)
      IRCP.Channel.publish(:channel, :test_callback)
      assert_receive {:handle_message_called, pid}
    end

    test "is called when a client receive a send_after message" do
      {:ok, pid} = ValidationClient.create(pid: self())
      :timer.send_after(10, pid, :test_callback)
      assert_receive {:handle_message_called, pid}
    end

    test "exits process when the return value is not {:noreply, _}" do
      Process.flag(:trap_exit, true)
      {:ok, pid} = ValidationClient.create()
      IRCP.Client.private_message(pid, :invalid_return)
      assert_receive {:EXIT, pid, {:shutdown, :bad_return_value}}
    end
  end

  describe "callback handle_question" do
    test "is called when a client receive a private message" do
      {:ok, pid} = ValidationClient.create(pid: self())
      assert :handle_question_called == IRCP.Client.private_question(pid, :test_callback)
    end

    test "returns :not_implemented when a client receives an unkwnown message" do
      {:ok, pid} = ValidationClient.create(pid: self())
      assert :not_implemented == IRCP.Client.private_question(pid, :unknown_message)
    end

    test "exits process when the return value is not {:reply, _, _}" do
      Process.flag(:trap_exit, true)
      {:ok, pid} = ValidationClient.create()
      catch_exit IRCP.Client.private_question(pid, :invalid_return)
      assert_receive {:EXIT, pid, {:shutdown, :bad_return_value}}
    end
  end
end
