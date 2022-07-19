defmodule ExBanking.Account.Actions.Deposit do
  @moduledoc false
  @type t :: %{amount: integer()}
  defstruct [:amount]
  alias ExBanking.Account
  alias ExBanking.Account.Actions.{Action, ActionResult}
  @behaviour Action

  @impl Action
  def apply_action(%Account{balance: balance} = state, %__MODULE__{amount: amount}) do
    new_state = Account.put_balance(state, balance + amount)
    {:ok, %ActionResult{state_after: new_state, result: new_state.balance}}
  end
end
