defmodule ExBanking.Account.Actions.GetBalance do
  @moduledoc false
  @type t :: %{}
  defstruct []
  alias ExBanking.Account
  alias ExBanking.Account.Actions.{Action, ActionResult}
  @behaviour Action

  @impl Action
  def apply_action(%Account{} = state, %__MODULE__{}) do
    {:ok, %ActionResult{state_after: state, result: state.balance}}
  end
end
