defmodule ExBanking.User do
  @moduledoc """
  GenServer storing user information with their Accounts info
  """
  use GenServer
  alias ExBanking.Account
  alias ExBanking.Formatter
  alias ExBanking.User.Actions.{Action, Deposit, GetBalance, Send, Withdraw}
  alias ExBanking.User.RequestThrottler
  @type t :: %{name: String.t()}

  @type action :: Deposit.t() | GetBalance.t() | Withdraw.t() | Send.t()

  @typep name :: String.t()
  @typep currency :: String.t()
  @typep amount :: integer()

  defstruct [:name]

  # Client

  def init(name) when is_binary(name) do
    {:ok, %__MODULE__{name: name}}
  end

  @spec create(String.t()) :: :ok | {:error, :user_already_exists | :wrong_arguments}
  def create(name) when is_binary(name) do
    case GenServer.start_link(__MODULE__, name, name: via(name)) do
      {:ok, _pid} ->
        RequestThrottler.init_counter(name)
        :ok

      {:error, {:already_started, _pid}} ->
        {:error, :user_already_exists}
    end
  end

  def create(_), do: {:error, :wrong_arguments}

  @spec deposit(name(), currency(), amount()) ::
          {:ok, integer()}
          | {:error, :user_does_not_exist | :too_many_requests_to_user | :wrong_arguments}
  def deposit(name, currency, amount)
      when is_binary(name) and is_binary(currency) and is_number(amount) and amount > 0 do
    call_by_name(name, %Deposit{amount: amount, currency: currency, name: name})
  end

  def deposit(_, _, _), do: {:error, :wrong_arguments}

  @spec get_balance(name(), currency()) ::
          {:ok, integer()}
          | {:error, :user_does_not_exist | :too_many_requests_to_user | :wrong_arguments}
  def get_balance(name, currency) when is_binary(name) and is_binary(currency) do
    call_by_name(name, %GetBalance{currency: currency, name: name})
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec send(name(), name(), currency(), amount()) ::
          {:ok, integer()}
          | {:error,
             :sender_does_not_exist
             | :too_many_requests_to_sender
             | :receiver_does_not_exist
             | :too_many_requests_to_receiver
             | :wrong_arguments}
  def send(from, to, currency, amount)
      when is_binary(from) and is_binary(to) and is_binary(currency) and is_number(amount) and
             amount > 0 do
    case call_by_name(from, %Send{from: from, to: to, amount: amount, currency: currency}) do
      {:ok, {from_balance, to_balance}} -> {:ok, from_balance, to_balance}
      e -> e
    end
  end

  def send(_, _, _, _), do: {:error, :wrong_arguments}

  def withdraw(name, currency, amount)
      when is_binary(name) and is_binary(currency) and is_number(amount) and amount > 0 do
    call_by_name(name, %Withdraw{amount: amount, currency: currency, name: name})
  end

  def withdraw(_, _, _), do: {:error, :wrong_arguments}

  # Server

  def handle_call(action, from, state) do
    spawn_link(fn ->
      apply_and_reply(action, from)
    end)

    {:noreply, state}
  end

  defp apply_and_reply(action, from) do
    reply =
      case Action.apply_action!(action) do
        {:error, e} -> {:error, e}
        result -> {:ok, result}
      end

    decrement_counters(action)
    GenServer.reply(from, Formatter.format_output(reply))
  end

  defp decrement_counters(%Send{to: receiver, from: sender}) do
    RequestThrottler.decrement_counter(sender)
    RequestThrottler.decrement_counter(receiver)
  end

  defp decrement_counters(%{name: name}) do
    RequestThrottler.decrement_counter(name)
  end

  defp call_by_name(name, action, too_many_requests_error \\ :too_many_requests_to_user)

  defp call_by_name(name, %Send{to: receiver, currency: currency} = action, _) do
    with {:ok, sender_pid} <- find_user(name, :sender_does_not_exist),
         {:ok, _receiver_pid} <- find_user(receiver, :receiver_does_not_exist),
         :ok <- Account.create_if_not_exists(name, currency),
         :ok <- Account.create_if_not_exists(receiver, currency),
         :ok <- check_requests_possible(name, receiver) do
      RequestThrottler.increment_counter(name)
      RequestThrottler.increment_counter(receiver)
      GenServer.call(sender_pid, action)
    end
  end

  defp call_by_name(name, action, too_many_requests_error) do
    with {:ok, user_pid} <- find_user(name),
         :ok <- Account.create_if_not_exists(name, action.currency),
         :ok <- check_request_possible(name, too_many_requests_error) do
      RequestThrottler.increment_counter(name)
      GenServer.call(user_pid, action)
    end
  end

  def find_user(name, user_not_found_error \\ :user_does_not_exist) do
    case Registry.lookup(Registry.User, name) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, user_not_found_error}
    end
  end

  def check_requests_possible(from, to) do
    with :ok <- check_request_possible(from, :too_many_requests_to_sender),
         :ok <- check_request_possible(to, :too_many_requests_to_receiver) do
      :ok
    else
      e -> e
    end
  end

  defp check_request_possible(name, too_many_requests_error) do
    if RequestThrottler.request_possible?(name) do
      :ok
    else
      {:error, too_many_requests_error}
    end
  end

  defp via(name), do: {:via, Registry, {Registry.User, name}}
end
