defmodule Alpa.Models.Trade do
  @moduledoc """
  Trade data model for market data.
  """
  use TypedStruct

  typedstruct do
    field :symbol, String.t()
    field :timestamp, DateTime.t()
    field :price, Decimal.t()
    field :size, integer()
    field :exchange, String.t()
    field :id, integer()
    field :conditions, [String.t()]
    field :tape, String.t()
    field :update, String.t()
  end

  @doc """
  Parse trade data from API response.
  """
  @spec from_map(map(), String.t() | nil) :: t()
  def from_map(data, symbol \\ nil) when is_map(data) do
    %__MODULE__{
      symbol: symbol || data["S"],
      timestamp: parse_datetime(data["t"]),
      price: parse_decimal(data["p"]),
      size: data["s"],
      exchange: data["x"],
      id: data["i"],
      conditions: data["c"],
      tape: data["z"],
      update: data["u"]
    }
  end

  @doc """
  Parse multiple trades from API response.
  """
  @spec from_response(map()) :: %{String.t() => [t()]} | [t()]
  def from_response(%{"trades" => trades}) when is_map(trades) do
    Map.new(trades, fn {symbol, trade_list} ->
      {symbol, Enum.map(trade_list, &from_map(&1, symbol))}
    end)
  end

  def from_response(%{"trades" => trades}) when is_list(trades) do
    Enum.map(trades, &from_map/1)
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
