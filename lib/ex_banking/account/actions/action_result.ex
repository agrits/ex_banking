defmodule ExBanking.Account.Actions.ActionResult do
  @moduledoc false
  alias ExBanking.Account
  defstruct [:state_after, :result]
  @type t :: %{state_after: Account.t(), result: any()}
end
