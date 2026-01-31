defmodule Alpa.Helpers do
  @moduledoc """
  Shared helper functions for parsing API response values.

  These helpers are used across model modules to convert raw API response
  strings into appropriate Elixir types (Decimal, DateTime, Date).
  """

  @doc """
  Parse a value into a `Decimal`.

  Handles nil, string, integer, and float inputs.

  ## Examples

      iex> Alpa.Helpers.parse_decimal("123.45")
      Decimal.new("123.45")

      iex> Alpa.Helpers.parse_decimal(nil)
      nil

  """
  @spec parse_decimal(nil | String.t() | integer() | float()) :: Decimal.t() | nil
  def parse_decimal(nil), do: nil
  def parse_decimal(value) when is_binary(value), do: Decimal.new(value)
  def parse_decimal(value) when is_integer(value), do: Decimal.new(value)
  def parse_decimal(value) when is_float(value), do: Decimal.from_float(value)

  @doc """
  Parse an ISO 8601 string into a `DateTime`.

  ## Examples

      iex> Alpa.Helpers.parse_datetime("2024-01-15T14:30:00Z")
      ~U[2024-01-15 14:30:00Z]

      iex> Alpa.Helpers.parse_datetime(nil)
      nil

  """
  @spec parse_datetime(nil | String.t()) :: DateTime.t() | nil
  def parse_datetime(nil), do: nil

  def parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  @doc """
  Parse an ISO 8601 string into a `Date`.

  ## Examples

      iex> Alpa.Helpers.parse_date("2024-01-15")
      ~D[2024-01-15]

      iex> Alpa.Helpers.parse_date(nil)
      nil

  """
  @spec parse_date(nil | String.t()) :: Date.t() | nil
  def parse_date(nil), do: nil

  def parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end
end
