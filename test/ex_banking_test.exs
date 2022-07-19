defmodule ExBankingTest do
  use ExUnit.Case
  doctest ExBanking
  @requests_limit 10

  setup_all do
    name1 = "artur"
    name2 = "yolo"
    ExBanking.create_user(name1)
    ExBanking.create_user(name2)
    %{name1: name1, name2: name2}
  end

  describe "create_user/1" do
    test "creates a new user with correct arguments" do
      name = "collin"
      ExBanking.create_user(name)
      assert [_] = Registry.lookup(Registry.User, name)
    end

    test "returns {:error, :wrong_arguments} when provided name is not a string" do
      assert ExBanking.create_user(:artur) == {:error, :wrong_arguments}
    end

    test "returns {:error, :user_already_exists} when trying to create a user with occupied name",
         %{name1: name} do
      assert ExBanking.create_user(name) == {:error, :user_already_exists}
    end
  end

  describe "deposit/1" do
    test "deposits money and returns balance for correct arguments", %{name1: name} do
      amount = 100.0
      assert {:ok, ^amount} = ExBanking.deposit(name, amount, "EUR")
    end

    test "returns {:error, :user_does_not_exist} when there's no user with given name" do
      assert ExBanking.deposit("non_existing", 13, "PLN") == {:error, :user_does_not_exist}
    end

    test "returns {:error, :wrong_arguments} when name is not a string" do
      assert ExBanking.deposit(:artur, 13, "EUR") == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when amount is not a number" do
      assert ExBanking.deposit("artur", "13", "EUR") == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when currency is not a string" do
      assert ExBanking.deposit("artur", 13, :EUR) == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when amount is not positive" do
      assert ExBanking.deposit("artur", 0, "EUR") == {:error, :wrong_arguments}
      assert ExBanking.deposit("artur", -1.5, "EUR") == {:error, :wrong_arguments}
    end

    test "holds two decimal places of precision", %{name1: name} do
      currency = "EUR"
      assert {:ok, 12.01} == ExBanking.deposit(name, 12.016, currency)
    end

    test "returns {:error, :too_many_requests_to_user} when requests to user reach the limit" do
      name = "test_deposit"
      ExBanking.create_user(name)
      requests_count = 1000

      finished_correctly =
        1..requests_count
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.deposit(name, 13, "EUR") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn res -> elem(res, 0) == :ok end)

      assert finished_correctly >= @requests_limit
      assert finished_correctly < requests_count
    end
  end

  describe "withdraw/1" do
    test "withdraws funds when args are correct and returns appropriate balance", %{name1: name} do
      currency = "EUR"
      to_deposit = 13.0
      to_withdraw = 10.0
      balance_after = to_deposit - to_withdraw
      ExBanking.deposit(name, to_deposit, currency)
      assert {:ok, ^balance_after} = ExBanking.withdraw(name, to_withdraw, currency)
    end

    test "returns {:error, :not_enough_money} when user does not have enough funds to withdraw",
         %{name1: name} do
      assert ExBanking.withdraw(name, 1, "EUR") == {:error, :not_enough_money}
    end

    test "returns {:error, :user_does_not_exist} when there's no such user" do
      assert ExBanking.withdraw("non_existing", 1, "EUR") == {:error, :user_does_not_exist}
    end

    test "returns {:error, :wrong_arguments} when name is not a string" do
      assert ExBanking.withdraw(:artur, 13, "EUR") == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when amount is not a number" do
      assert ExBanking.withdraw("artur", "13", "EUR") == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when currency is not a string" do
      assert ExBanking.withdraw("artur", 13, :EUR) == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when amount is not positive" do
      assert ExBanking.withdraw("artur", 0, "EUR") == {:error, :wrong_arguments}
      assert ExBanking.withdraw("artur", -1.5, "EUR") == {:error, :wrong_arguments}
    end

    test "holds two decimal places of precision", %{name1: name} do
      currency = "EUR"
      assert {:ok, 12.01} == ExBanking.deposit(name, 12.016, currency)
      assert {:ok, 11.0} == ExBanking.withdraw(name, 1.016, currency)
    end

    test "returns {:error, :too_many_requests_to_user} when requests to user reach the limit" do
      name = "withdraw_test"
      currency = "EUR"
      ExBanking.create_user(name)
      requests_count = 1000
      ExBanking.deposit(name, requests_count * 2, currency)

      finished_correctly =
        1..requests_count
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.withdraw(name, 1, currency) end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn res -> elem(res, 0) == :ok end)

      assert finished_correctly >= @requests_limit
      assert finished_correctly < requests_count
    end
  end

  describe "get_balance/1" do
    test "returns correct balance", %{name1: name} do
      currency = "EUR"
      to_deposit = 13.0
      assert {:ok, 0.0} = ExBanking.get_balance(name, currency)
      ExBanking.deposit(name, to_deposit, currency)
      assert {:ok, ^to_deposit} = ExBanking.get_balance(name, currency)
    end

    test "returns {:error, :user_does_not_exist} when there's no such user" do
      assert ExBanking.get_balance("non_existing", "EUR") == {:error, :user_does_not_exist}
    end

    test "returns {:error, :wrong_arguments} when name is not a string" do
      assert ExBanking.get_balance(:artur, "EUR") == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when currency is not a string" do
      assert ExBanking.get_balance("artur", :EUR) == {:error, :wrong_arguments}
    end

    test "returns {:error, :too_many_requests_to_user} when requests to user reach the limit" do
      name = "test_get_balance"
      ExBanking.create_user(name)
      requests_count = 1000

      finished_correctly =
        1..requests_count
        |> Enum.map(fn _ ->
          Task.async(fn -> ExBanking.get_balance(name, "EUR") end)
        end)
        |> Enum.map(&Task.await/1)
        |> Enum.count(fn res -> elem(res, 0) == :ok end)

      assert finished_correctly >= @requests_limit
      assert finished_correctly < requests_count
    end
  end

  describe "send/1" do
    test "transfers money and returns correct balances of sender and receiver for correct args",
         %{name1: name1, name2: name2} do
      amount = 13.0
      currency = "EUR"
      ExBanking.deposit(name1, amount, currency)
      assert {:ok, 0.0, ^amount} = ExBanking.send(name1, name2, amount, currency)
      assert {:ok, 0.0} = ExBanking.get_balance(name1, currency)
      assert {:ok, ^amount} = ExBanking.get_balance(name2, currency)
    end

    test "returns {:error, :wrong_arguments} when name is not a string" do
      assert ExBanking.send(:whatever, "whatever2", 13, "EUR") == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when amount is not a number" do
      assert ExBanking.send("whatever", "whatever2", "13", "EUR") == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when currency is not a string" do
      assert ExBanking.send("whatever", "whatever2", 13, :EUR) == {:error, :wrong_arguments}
    end

    test "returns {:error, :wrong_arguments} when amount is not positive" do
      assert ExBanking.send("whatever", "whatever2", 0, "EUR") == {:error, :wrong_arguments}
      assert ExBanking.send("whatever", "whatever2", -1.5, "EUR") == {:error, :wrong_arguments}
    end

    test "returns {:error, :sender_does_not_exist} when sender does not exist", %{name1: name} do
      assert ExBanking.send("non_existing", name, 5, "EUR") == {:error, :sender_does_not_exist}
    end

    test "returns {:error, :receiver_does_not_exist} when receiver does not exist", %{name1: name} do
      currency = "EUR"
      amount = 13
      ExBanking.deposit(name, amount, currency)

      assert ExBanking.send(name, "non_existing", amount, currency) ==
               {:error, :receiver_does_not_exist}
    end

    test "returns {:error, :too_many_requests_to_sender} when requests to sender reach the limit" do
      sender = "send_test_sender"
      receiver = "send_test_receiver"
      currency = "EUR"

      ExBanking.create_user(sender)
      ExBanking.create_user(receiver)
      ExBanking.deposit(sender, 20_000, currency)

      send_tasks =
        1..10_000 |> Enum.map(fn _ -> fn -> ExBanking.send(sender, receiver, 1, currency) end end)

      assert send_tasks
             |> Enum.map(&Task.async/1)
             |> Enum.map(&Task.await/1)
             |> Enum.any?(fn res -> res |> elem(0) == :error end)
    end

    test "returns {:error, :too_many_requests_to_receiver} when requests to receiver reach the limit" do
      sender = "send_test_sender"
      receiver = "send_test_receiver"
      currency = "EUR"

      ExBanking.create_user(sender)
      ExBanking.create_user(receiver)
      ExBanking.deposit(sender, 2000, currency)

      deposit_tasks =
        1..10_000 |> Enum.map(fn _ -> fn -> ExBanking.deposit(receiver, 1, currency) end end)

      send_tasks =
        1..1000 |> Enum.map(fn _ -> fn -> ExBanking.send(sender, receiver, 1, currency) end end)

      tasks = deposit_tasks ++ send_tasks

      assert tasks
             |> Enum.shuffle()
             |> Enum.map(&Task.async/1)
             |> Enum.map(&Task.await/1)
             |> Enum.any?(fn res -> res |> elem(0) == :error end)
    end
  end
end
