defmodule ExBanking.User.Actions.Deposit do
  @moduledoc false
  @type t :: %{amount: integer(), currency: String.t(), name: String.t()}
  @keys [:amount, :currency, :name]
  @enforce_keys @keys
  defstruct @keys
  alias ExBanking.Account
  alias ExBanking.User.Actions.Action
  @behaviour Action

  @impl Action
  def apply_action(%__MODULE__{amount: amount, currency: currency, name: name}) do
    Account.deposit(name, currency, amount)
  end
end
