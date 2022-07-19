defmodule ExBanking.Account do
  @moduledoc """
  GenServer storing amount of funds in given currency.
  """
  use GenServer

  alias ExBanking.Account.Actions.{Action, ActionResult, Deposit, GetBalance, Withdraw, Send}
  defstruct [:balance, :currency]

  @type t :: %{
          balance: integer(),
          currency: String.t()
        }

  @type action :: Deposit.t() | GetBalance.t() | Withdraw.t() | Send.t()

  @typep name :: String.t()
  @typep currency :: String.t()
  @typep amount :: integer()
  @typep balance_after :: integer()
  @typep sender_balance :: integer()
  @typep receiver_balance :: integer()

  def init(currency) do
    {:ok, %__MODULE__{balance: 0, currency: currency}}
  end

  @spec create_if_not_exists(String.t(), String.t()) :: :ok
  def create_if_not_exists(name, currency) do
    case GenServer.start_link(__MODULE__, currency, name: via(name, currency)) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end

  @spec deposit(String.t(), String.t(), integer()) :: balance_after()
  def deposit(name, currency, amount) do
    call_by_name_and_currency(name, currency, %Deposit{amount: amount})
  end

  @spec withdraw(name(), currency(), amount()) :: balance_after() | {:error, :not_enough_money}
  def withdraw(name, currency, amount) do
    call_by_name_and_currency(name, currency, %Withdraw{amount: amount})
  end

  @spec get_balance(name(), currency()) :: balance_after()
  def get_balance(name, currency) do
    call_by_name_and_currency(name, currency, %GetBalance{})
  end

  @spec send(name(), name(), currency(), amount()) ::
          {sender_balance(), receiver_balance()} | {:error, :not_enough_money}
  def send(from, to, currency, amount) do
    call_by_name_and_currency(from, currency, %Send{to: via(to, currency), amount: amount})
  end

  def handle_call(action, _from, state) do
    case Action.apply_action!(action, state) do
      {:ok, %ActionResult{state_after: state_after, result: result}} ->
        {:reply, result, state_after}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  @doc """
  Update balance in the state
  """
  @spec put_balance(t(), integer()) :: t()
  def put_balance(%__MODULE__{} = state, balance) do
    struct(state, balance: balance)
  end

  defp call_by_name_and_currency(name, currency, action) do
    GenServer.call(via(name, currency), action)
  end

  defp via(name, currency), do: {:via, Registry, {Registry.Account, {name, currency}}}
end
