defmodule Alpa.Models.Quote do
  @moduledoc """
  Quote (NBBO) data model for market data.
  """
  use TypedStruct
  import Alpa.Helpers, only: [parse_decimal: 1, parse_datetime: 1]

  typedstruct do
    field :symbol, String.t()
    field :timestamp, DateTime.t()
    field :ask_price, Decimal.t()
    field :ask_size, integer()
    field :ask_exchange, String.t()
    field :bid_price, Decimal.t()
    field :bid_size, integer()
    field :bid_exchange, String.t()
    field :conditions, [String.t()]
    field :tape, String.t()
  end

  @doc """
  Parse quote data from API response.
  """
  @spec from_map(map(), String.t() | nil) :: t()
  def from_map(data, symbol \\ nil) when is_map(data) do
    %__MODULE__{
      symbol: symbol || data["S"],
      timestamp: parse_datetime(data["t"]),
      ask_price: parse_decimal(data["ap"]),
      ask_size: data["as"],
      ask_exchange: data["ax"],
      bid_price: parse_decimal(data["bp"]),
      bid_size: data["bs"],
      bid_exchange: data["bx"],
      conditions: data["c"],
      tape: data["z"]
    }
  end

  @doc """
  Parse multiple quotes from API response.
  """
  @spec from_response(map()) :: %{String.t() => [t()]} | [t()]
  def from_response(%{"quotes" => quotes}) when is_map(quotes) do
    Map.new(quotes, fn {symbol, quote_list} ->
      {symbol, Enum.map(quote_list, &from_map(&1, symbol))}
    end)
  end

  def from_response(%{"quotes" => quotes}) when is_list(quotes) do
    Enum.map(quotes, &from_map/1)
  end

  def from_response(data), do: data

end
