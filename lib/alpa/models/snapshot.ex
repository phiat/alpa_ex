defmodule Alpa.Models.Snapshot do
  @moduledoc """
  Market snapshot combining latest trade, quote, minute bar, daily bar, and previous daily bar.
  """
  use TypedStruct

  alias Alpa.Models.{Bar, Quote, Trade}

  typedstruct do
    field(:symbol, String.t())
    field(:latest_trade, Trade.t())
    field(:latest_quote, Quote.t())
    field(:minute_bar, Bar.t())
    field(:daily_bar, Bar.t())
    field(:prev_daily_bar, Bar.t())
  end

  @doc """
  Parse snapshot data from API response.
  """
  @spec from_map(map(), String.t()) :: t()
  def from_map(data, symbol) when is_map(data) do
    %__MODULE__{
      symbol: symbol,
      latest_trade: parse_trade(data["latestTrade"], symbol),
      latest_quote: parse_quote(data["latestQuote"], symbol),
      minute_bar: parse_bar(data["minuteBar"], symbol),
      daily_bar: parse_bar(data["dailyBar"], symbol),
      prev_daily_bar: parse_bar(data["prevDailyBar"], symbol)
    }
  end

  @doc """
  Parse multiple snapshots from API response.
  """
  @spec from_response(map()) :: %{String.t() => t()}
  def from_response(%{"snapshots" => snapshots}) when is_map(snapshots) do
    Map.new(snapshots, fn {symbol, data} ->
      {symbol, from_map(data, symbol)}
    end)
  end

  def from_response(data) when is_map(data) do
    # The multi-snapshot API returns data directly as %{"AAPL" => %{...}, ...}
    # Check if the values look like snapshot data (have "latestTrade" key)
    if Enum.any?(data, fn {_k, v} -> is_map(v) and Map.has_key?(v, "latestTrade") end) do
      Map.new(data, fn {symbol, snap_data} ->
        {symbol, from_map(snap_data, symbol)}
      end)
    else
      data
    end
  end

  def from_response(data), do: data

  defp parse_trade(nil, _symbol), do: nil
  defp parse_trade(data, symbol), do: Trade.from_map(data, symbol)

  defp parse_quote(nil, _symbol), do: nil
  defp parse_quote(data, symbol), do: Quote.from_map(data, symbol)

  defp parse_bar(nil, _symbol), do: nil
  defp parse_bar(data, symbol), do: Bar.from_map(data, symbol)
end
