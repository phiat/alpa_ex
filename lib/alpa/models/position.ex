defmodule Alpa.Models.Position do
  @moduledoc """
  Position model for portfolio holdings.
  """
  use TypedStruct

  @type side :: :long | :short

  typedstruct do
    field :asset_id, String.t()
    field :symbol, String.t()
    field :exchange, String.t()
    field :asset_class, String.t()
    field :asset_marginable, boolean()
    field :qty, Decimal.t()
    field :avg_entry_price, Decimal.t()
    field :side, side()
    field :market_value, Decimal.t()
    field :cost_basis, Decimal.t()
    field :unrealized_pl, Decimal.t()
    field :unrealized_plpc, Decimal.t()
    field :unrealized_intraday_pl, Decimal.t()
    field :unrealized_intraday_plpc, Decimal.t()
    field :current_price, Decimal.t()
    field :lastday_price, Decimal.t()
    field :change_today, Decimal.t()
    field :qty_available, Decimal.t()
  end

  @doc """
  Parse position data from API response.
  """
  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      asset_id: data["asset_id"],
      symbol: data["symbol"],
      exchange: data["exchange"],
      asset_class: data["asset_class"],
      asset_marginable: data["asset_marginable"],
      qty: parse_decimal(data["qty"]),
      avg_entry_price: parse_decimal(data["avg_entry_price"]),
      side: parse_side(data["side"]),
      market_value: parse_decimal(data["market_value"]),
      cost_basis: parse_decimal(data["cost_basis"]),
      unrealized_pl: parse_decimal(data["unrealized_pl"]),
      unrealized_plpc: parse_decimal(data["unrealized_plpc"]),
      unrealized_intraday_pl: parse_decimal(data["unrealized_intraday_pl"]),
      unrealized_intraday_plpc: parse_decimal(data["unrealized_intraday_plpc"]),
      current_price: parse_decimal(data["current_price"]),
      lastday_price: parse_decimal(data["lastday_price"]),
      change_today: parse_decimal(data["change_today"]),
      qty_available: parse_decimal(data["qty_available"])
    }
  end

  defp parse_decimal(nil), do: nil
  defp parse_decimal(value) when is_binary(value), do: Decimal.new(value)
  defp parse_decimal(value) when is_integer(value), do: Decimal.new(value)
  defp parse_decimal(value) when is_float(value), do: Decimal.from_float(value)

  defp parse_side("long"), do: :long
  defp parse_side("short"), do: :short
  defp parse_side(_), do: nil
end
