defmodule ExBanking.Account.Actions.Send do
  @moduledoc false
  @type t :: %{amount: integer(), to: pid()}
  defstruct [:amount, :to]
  alias ExBanking.Account
  alias ExBanking.Account.Actions.{Action, ActionResult, Deposit}

  @behaviour Action

  @impl Action
  def apply_action(%Account{balance: balance} = state, %__MODULE__{amount: amount, to: to_account})
      when balance >= amount do
    new_state = Account.put_balance(state, balance - amount)
    new_to_balance = GenServer.call(to_account, %Deposit{amount: amount})
    {:ok, %ActionResult{state_after: new_state, result: {new_state.balance, new_to_balance}}}
  end

  def apply_action(_, _) do
    {:error, :not_enough_money}
  end
end
