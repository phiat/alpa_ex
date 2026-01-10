defmodule Alpa.Models.Bar do
  @moduledoc """
  OHLCV bar data model for market data.
  """
  use TypedStruct

  typedstruct do
    field :symbol, String.t()
    field :timestamp, DateTime.t()
    field :open, Decimal.t()
    field :high, Decimal.t()
    field :low, Decimal.t()
    field :close, Decimal.t()
    field :volume, integer()
    field :trade_count, integer()
    field :vwap, Decimal.t()
  end

  @doc """
  Parse bar data from API response.
  """
  @spec from_map(map(), String.t() | nil) :: t()
  def from_map(data, symbol \\ nil) when is_map(data) do
    %__MODULE__{
      symbol: symbol || data["S"],
      timestamp: parse_datetime(data["t"]),
      open: parse_decimal(data["o"]),
      high: parse_decimal(data["h"]),
      low: parse_decimal(data["l"]),
      close: parse_decimal(data["c"]),
      volume: data["v"],
      trade_count: data["n"],
      vwap: parse_decimal(data["vw"])
    }
  end

  @doc """
  Parse multiple bars from API response.
  """
  @spec from_response(map()) :: %{String.t() => [t()]} | [t()] | map()
  def from_response(%{"bars" => nil}), do: %{}

  def from_response(%{"bars" => bars}) when is_map(bars) do
    Map.new(bars, fn {symbol, bar_list} ->
      {symbol, Enum.map(bar_list, &from_map(&1, symbol))}
    end)
  end

  def from_response(%{"bars" => bars}) when is_list(bars) do
    Enum.map(bars, &from_map/1)
  end

  def from_response(data), do: data

  defp parse_decimal(nil), do: nil
  defp parse_decimal(value) when is_binary(value), do: Decimal.new(value)
  defp parse_decimal(value) when is_number(value), do: Decimal.from_float(value / 1)

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end
end
