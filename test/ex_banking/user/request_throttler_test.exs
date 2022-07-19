defmodule ExBanking.User.RequestThrottlerTest do
  use ExUnit.Case
  alias ExBanking.User.RequestThrottler

  describe "init_counter/1" do
    test "creates counter for given name" do
      name = "test_init"
      RequestThrottler.init_counter(name)
      assert :ets.lookup(String.to_atom(name), :requests) == [{:requests, 0}]
    end
  end

  describe "increment_counter/1" do
    test "increments counter by 1 every time" do
      name = "test_increment"
      RequestThrottler.init_counter(name)
      count = 10

      for _ <- 1..count do
        RequestThrottler.increment_counter(name)
      end

      assert :ets.lookup(String.to_atom(name), :requests) == [{:requests, count}]
    end
  end

  describe "decrement_counter/1" do
    test "decrements counter by 1 every time" do
      name = "test_decrement"
      RequestThrottler.init_counter(name)
      count = 10
      :ets.insert(String.to_atom(name), {:requests, count})

      for _ <- 1..count do
        RequestThrottler.decrement_counter(name)
      end

      assert :ets.lookup(String.to_atom(name), :requests) == [{:requests, 0}]
    end
  end

  describe "request_possible?/1" do
    test "returns true when counter is below the limit" do
      name = "test_decrement"
      RequestThrottler.init_counter(name)
      count = 9
      :ets.insert(String.to_atom(name), {:requests, count})
      assert RequestThrottler.request_possible?(name)
    end

    test "returns false when counter is equal to or above the limit" do
      name = "test_decrement"
      RequestThrottler.init_counter(name)
      count = 11
      :ets.insert(String.to_atom(name), {:requests, count})
      refute RequestThrottler.request_possible?(name)
      RequestThrottler.decrement_counter(name)
      refute RequestThrottler.request_possible?(name)
    end
  end
end
