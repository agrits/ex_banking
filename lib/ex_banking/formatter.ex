defmodule ExBanking.Formatter do
  @moduledoc """
  Used to format money information in&out of the system.
  """
  @precision 2

  @spec format_input(number()) :: integer()
  def format_input(input), do: round(:math.floor(input * :math.pow(10, @precision)))

  @spec format_output({:ok, integer()} | {:ok, {integer(), integer()}} | {:error, any()}) ::
          {:ok, float()} | {:ok, float(), float()} | {:error, any()}
  def format_output({:ok, {output1, output2}}),
    do: {:ok, {output1 / :math.pow(10, @precision), output2 / :math.pow(10, @precision)}}

  def format_output({:ok, output}), do: {:ok, output / :math.pow(10, @precision)}
  def format_output({:error, _} = e), do: e
end
