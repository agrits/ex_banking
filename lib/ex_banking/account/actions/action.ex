defmodule ExBanking.Account.Actions.Action do
  @moduledoc false
  alias ExBanking.Account

  @doc """
  Apply action to account state and return the result.
  """
  @callback apply_action(Account.t(), struct()) :: {:ok, {Account.t(), any()}} | {:error, any()}

  def apply_action!(action, state) do
    action.__struct__.apply_action(state, action)
  end
end
