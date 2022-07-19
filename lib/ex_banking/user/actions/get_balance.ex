defmodule ExBanking.User.Actions.GetBalance do
  @moduledoc false
  @type t :: %{currency: String.t(), name: String.t()}
  @keys [:currency, :name]
  @enforce_keys @keys
  defstruct @keys
  alias ExBanking.Account
  alias ExBanking.User.Actions.Action
  @behaviour Action

  @impl Action
  def apply_action(%__MODULE__{currency: currency, name: name}) do
    Account.get_balance(name, currency)
  end
end
