defmodule ExBanking.User.RequestThrottler do
  @moduledoc """
  Used for throttling requests coming to users
  """
  @requests_limit 10

  @doc """
  Initialize counter for given user
  """
  @spec init_counter(String.t()) :: true
  def init_counter(name) do
    :ets.new(:"#{name}", [:ordered_set, :public, :named_table])
    :ets.insert(:"#{name}", {:requests, 0})
  end

  @doc """
  Check if request to user is possible at the moment.
  """
  @spec request_possible?(String.t()) :: boolean()
  def request_possible?(name), do: get_counter(name) < @requests_limit

  @doc """
  Increment request counter for given user
  """
  @spec increment_counter(String.t()) :: true
  def increment_counter(name) do
    current_counter = get_counter(name)
    :ets.insert(:"#{name}", {:requests, current_counter + 1})
  end

  @doc """
  Decrement request counter for given user
  """
  @spec decrement_counter(String.t()) :: true
  def decrement_counter(name) do
    current_counter = get_counter(name)
    :ets.insert(:"#{name}", {:requests, current_counter - 1})
  end

  defp get_counter(name), do: :ets.lookup_element(:"#{name}", :requests, 2)
end
