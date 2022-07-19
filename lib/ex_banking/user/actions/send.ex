defmodule ExBanking.User.Actions.Send do
  @moduledoc false
  @type t :: %{amount: integer(), from: String.t(), to: String.t(), currency: String.t()}
  @keys [:amount, :currency, :from, :to]
  @enforce_keys @keys
  defstruct @keys
  alias ExBanking.Account
  alias ExBanking.User.Actions.Action
  @behaviour Action

  @impl Action
  def apply_action(%__MODULE__{amount: amount, currency: currency, from: from, to: to}) do
    Account.send(from, to, currency, amount)
  end
end
