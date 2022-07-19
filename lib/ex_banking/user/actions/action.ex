defmodule ExBanking.User.Actions.Action do
  @moduledoc false
  @doc """
  Apply action to user state and return the result.
  """
  alias ExBanking.Formatter
  @callback apply_action(struct()) :: any() | {:error, any()}

  def apply_action!(%{amount: amount} = action) do
    action
    |> Map.put(:amount, Formatter.format_input(amount))
    |> action.__struct__.apply_action()
  end

  def apply_action!(action), do: action.__struct__.apply_action(action)
end
