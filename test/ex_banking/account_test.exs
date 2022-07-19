defmodule ExBanking.AccountTest do
  use ExUnit.Case
  alias ExBanking.Account

  describe "create_if_not_exists/2" do
    test "creates a GenServer process with state of balance = 0 and appropriate currency" do
      currency = "USD"
      name = "johndoe"

      Account.create_if_not_exists(name, currency)

      pid = GenServer.whereis({:via, Registry, {Registry.Account, {name, currency}}})

      assert %Account{balance: 0, currency: ^currency} = :sys.get_state(pid)
    end

    test "does not alter state if server for given name and currency already exists" do
      currency = "USD"
      name = "johndoe"

      Account.create_if_not_exists(name, currency)
      pid = GenServer.whereis({:via, Registry, {Registry.Account, {name, currency}}})
      balance = 13
      :sys.replace_state(pid, fn state -> Account.put_balance(state, balance) end)

      Account.create_if_not_exists(name, currency)

      assert %Account{balance: balance, currency: currency} == :sys.get_state(pid)
    end

    test "is case sensitive for currency" do
      currency1 = "USD"
      name1 = "johndoe"

      currency2 = "Usd"
      name2 = "johndoe"

      Account.create_if_not_exists(name1, currency1)
      Account.create_if_not_exists(name2, currency2)

      pid1 = GenServer.whereis({:via, Registry, {Registry.Account, {name1, currency1}}})
      pid2 = GenServer.whereis({:via, Registry, {Registry.Account, {name2, currency2}}})

      assert pid1 != pid2
      assert %Account{balance: 0, currency: ^currency1} = :sys.get_state(pid1)
      assert %Account{balance: 0, currency: ^currency2} = :sys.get_state(pid2)
    end

    test "is case sensitive for name" do
      currency1 = "USD"
      name1 = "johndoe"

      currency2 = "USD"
      name2 = "Johndoe"

      Account.create_if_not_exists(name1, currency1)
      Account.create_if_not_exists(name2, currency2)

      pid1 = GenServer.whereis({:via, Registry, {Registry.Account, {name1, currency1}}})
      pid2 = GenServer.whereis({:via, Registry, {Registry.Account, {name2, currency2}}})

      assert pid1 != pid2
      assert %Account{balance: 0, currency: ^currency1} = :sys.get_state(pid1)
      assert %Account{balance: 0, currency: ^currency2} = :sys.get_state(pid2)
    end
  end

  describe "deposit/3" do
    setup do
      name = "johndoe"
      Account.create_if_not_exists(name, "USD")
      Account.create_if_not_exists(name, "EUR")
      usd_pid = GenServer.whereis({:via, Registry, {Registry.Account, {name, "USD"}}})
      eur_pid = GenServer.whereis({:via, Registry, {Registry.Account, {name, "EUR"}}})
      %{name: name, usd_pid: usd_pid, eur_pid: eur_pid}
    end

    test "deposits funds to account balance in appropriate currency", %{
      name: name,
      usd_pid: usd_pid,
      eur_pid: eur_pid
    } do
      amount_usd = 150
      amount_usd2 = 50
      amount_eur = 100
      assert amount_usd = Account.deposit(name, "USD", amount_usd)
      assert amount_eur = Account.deposit(name, "EUR", amount_eur)
      assert %Account{balance: ^amount_usd, currency: "USD"} = :sys.get_state(usd_pid)
      assert %Account{balance: ^amount_eur, currency: "EUR"} = :sys.get_state(eur_pid)
      assert Account.deposit(name, "USD", amount_usd2) == amount_usd + amount_usd2

      assert %Account{balance: amount_usd + amount_usd2, currency: "USD"} ==
               :sys.get_state(usd_pid)
    end
  end

  describe "withdraw/3" do
    setup do
      name = "johndoe"
      Account.create_if_not_exists(name, "USD")
      Account.create_if_not_exists(name, "EUR")

      usd_pid = GenServer.whereis({:via, Registry, {Registry.Account, {name, "USD"}}})
      eur_pid = GenServer.whereis({:via, Registry, {Registry.Account, {name, "EUR"}}})
      %{name: name, usd_pid: usd_pid, eur_pid: eur_pid}
    end

    test "deducts funds from account balance in appropriate currency", %{
      name: name,
      usd_pid: usd_pid,
      eur_pid: eur_pid
    } do
      amount_usd = 150
      amount_eur = 100
      Account.deposit(name, "USD", amount_usd)
      Account.deposit(name, "EUR", amount_eur)

      minus_usd1 = 50
      minus_usd2 = 50
      minus_eur = 30

      assert amount_usd - minus_usd1 == Account.withdraw(name, "USD", minus_usd1)
      assert amount_eur - minus_eur == Account.withdraw(name, "EUR", minus_eur)

      assert %Account{balance: amount_usd - minus_usd1, currency: "USD"} ==
               :sys.get_state(usd_pid)

      assert %Account{balance: amount_eur - minus_eur, currency: "EUR"} == :sys.get_state(eur_pid)
      assert Account.withdraw(name, "USD", minus_usd2) == amount_usd - minus_usd1 - minus_usd2

      assert %Account{balance: amount_usd - minus_usd1 - minus_usd2, currency: "USD"} ==
               :sys.get_state(usd_pid)
    end

    test "returns {:error, :not_enough_money} and does not impact state when called with more amount than available in account",
         %{name: name, usd_pid: usd_pid} do
      amount_usd = 150
      assert {:error, :not_enough_money} = Account.withdraw(name, "USD", amount_usd)
      assert %Account{currency: "USD", balance: 0} = :sys.get_state(usd_pid)
    end
  end

  describe "get_balance/2" do
    setup do
      name = "johndoe"
      Account.create_if_not_exists(name, "USD")
      Account.create_if_not_exists(name, "EUR")

      usd_pid = GenServer.whereis({:via, Registry, {Registry.Account, {name, "USD"}}})
      eur_pid = GenServer.whereis({:via, Registry, {Registry.Account, {name, "EUR"}}})
      %{name: name, usd_pid: usd_pid, eur_pid: eur_pid}
    end

    test "returns appropriate balance and does not impact state", %{
      name: name,
      usd_pid: usd_pid,
      eur_pid: eur_pid
    } do
      amount_usd = 100
      amount_eur = 150

      assert amount_usd == Account.deposit(name, "USD", amount_usd)
      assert amount_eur == Account.deposit(name, "EUR", amount_eur)

      assert amount_usd == Account.get_balance(name, "USD")
      assert amount_eur == Account.get_balance(name, "EUR")

      assert %Account{currency: "USD", balance: amount_usd} == :sys.get_state(usd_pid)
      assert %Account{currency: "EUR", balance: amount_eur} == :sys.get_state(eur_pid)
    end
  end

  describe "send/3" do
    setup do
      john = "johndoe"
      ann = "anndoe"
      Account.create_if_not_exists(john, "USD")
      Account.create_if_not_exists(john, "EUR")
      Account.create_if_not_exists(ann, "USD")
      Account.create_if_not_exists(ann, "EUR")

      john_usd_pid = GenServer.whereis({:via, Registry, {Registry.Account, {john, "USD"}}})
      john_eur_pid = GenServer.whereis({:via, Registry, {Registry.Account, {john, "EUR"}}})
      ann_usd_pid = GenServer.whereis({:via, Registry, {Registry.Account, {ann, "USD"}}})
      ann_eur_pid = GenServer.whereis({:via, Registry, {Registry.Account, {ann, "EUR"}}})

      %{
        john: john,
        ann: ann,
        john_usd_pid: john_usd_pid,
        john_eur_pid: john_eur_pid,
        ann_usd_pid: ann_usd_pid,
        ann_eur_pid: ann_eur_pid
      }
    end

    test "subtracts money from sender's account and deposits to receiver's account", %{
      john: john,
      ann: ann,
      john_usd_pid: john_usd_pid,
      john_eur_pid: john_eur_pid,
      ann_usd_pid: ann_usd_pid,
      ann_eur_pid: ann_eur_pid
    } do
      amount_usd = 110
      usd_to_send = 50
      assert amount_usd == Account.deposit(john, "USD", amount_usd)

      assert {amount_usd - usd_to_send, usd_to_send} ==
               Account.send(john, ann, "USD", usd_to_send)

      assert %Account{currency: "USD", balance: usd_to_send} == :sys.get_state(ann_usd_pid)
      assert %Account{currency: "EUR", balance: 0} == :sys.get_state(ann_eur_pid)

      assert %Account{currency: "USD", balance: amount_usd - usd_to_send} ==
               :sys.get_state(john_usd_pid)

      assert %Account{currency: "EUR", balance: 0} == :sys.get_state(john_eur_pid)
    end

    test "returns {:error, :not_enough_money} when the amount execeeds sender's balance", %{
      john: john,
      ann: ann,
      john_usd_pid: john_usd_pid,
      john_eur_pid: john_eur_pid,
      ann_usd_pid: ann_usd_pid,
      ann_eur_pid: ann_eur_pid
    } do
      assert {:error, :not_enough_money} == Account.send(john, ann, "USD", 1)
      assert %Account{currency: "USD", balance: 0} == :sys.get_state(ann_usd_pid)
      assert %Account{currency: "EUR", balance: 0} == :sys.get_state(ann_eur_pid)
      assert %Account{currency: "USD", balance: 0} == :sys.get_state(john_usd_pid)
      assert %Account{currency: "EUR", balance: 0} == :sys.get_state(john_eur_pid)
    end
  end
end
