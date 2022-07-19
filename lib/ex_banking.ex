defmodule ExBanking do
  @moduledoc """
  Simulation of simple banking system with use of Elixir and OTP.

  Holds 2 decimal places of precision.
  """
  alias ExBanking.User

  @doc """
  Create a new user.

  ## Examples
  iex> ExBanking.create_user("john")
  :ok
  iex> ExBanking.create_user("jose")
  :ok
  """
  @spec create_user(user :: String.t()) ::
          :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    User.create(user)
  end

  @doc """
  Deposit a given amount in given currency at given user's account.

  ## Examples
  iex> ExBanking.create_user("john")
  iex> ExBanking.create_user("jose")
  iex> ExBanking.deposit("john", 13.003, "EUR")
  {:ok, 13.0}
  iex> ExBanking.deposit("john", -1.5, "EUR")
  {:error, :wrong_arguments}
  iex> ExBanking.deposit("non_existing", 1, "EUR")
  {:error, :user_does_not_exist}
  """
  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency) do
    user
    |> User.deposit(currency, amount)
  end

  @doc """
  Withdraw a given amount in given currency from given user's account.

  ## Examples
  iex> ExBanking.create_user("john")
  iex> ExBanking.deposit("john", 13, "EUR")
  iex> ExBanking.withdraw("john", 1, "EUR")
  {:ok, 12.0}
  iex> ExBanking.withdraw("john", -1.5, "EUR")
  {:error, :wrong_arguments}
  iex> ExBanking.withdraw("non_existing", 1, "EUR")
  {:error, :user_does_not_exist}
  iex> ExBanking.withdraw("john", 100, "EUR")
  {:error, :not_enough_money}
  """
  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency) do
    user
    |> User.withdraw(currency, amount)
  end

  @doc """
  Get balance in given currency of given user's account.

  ## Examples
  iex> ExBanking.create_user("john")
  iex> ExBanking.deposit("john", 12, "EUR")
  iex> ExBanking.get_balance("john", "EUR")
  {:ok, 12.0}
  iex> ExBanking.get_balance("john", "USD")
  {:ok, 0.0}
  iex> ExBanking.get_balance("non_existing", "USD")
  {:error, :user_does_not_exist}
  """
  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) do
    user
    |> User.get_balance(currency)
  end

  @doc """
  Send a given amount in given currency from one user to another.

  ## Examples
  iex> ExBanking.create_user("john")
  iex> ExBanking.create_user("jose")
  iex> ExBanking.deposit("john", 12, "EUR")
  iex> ExBanking.send("john", "jose", 1, "EUR")
  {:ok, 11.0, 1.0}
  iex> ExBanking.send("john", "jose", 100, "EUR")
  {:error, :not_enough_money}
  iex> ExBanking.send("john", "non_existing", 100, "EUR")
  {:error, :receiver_does_not_exist}
  iex> ExBanking.send("non_existing", "jose", 100, "EUR")
  {:error, :sender_does_not_exist}
  """
  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency) do
    from_user
    |> User.send(to_user, currency, amount)
  end
end
