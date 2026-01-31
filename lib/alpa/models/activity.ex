defmodule Alpa.Models.Activity do
  @moduledoc """
  Account activity model for trades, dividends, fees, etc.
  """
  use TypedStruct

  typedstruct do
    field :id, String.t()
    field :activity_type, String.t()
    field :date, Date.t()
    field :net_amount, Decimal.t()
    field :symbol, String.t()
    field :qty, Decimal.t()
    field :per_share_amount, Decimal.t()
    field :price, Decimal.t()
    field :cum_qty, Decimal.t()
    field :leaves_qty, Decimal.t()
    field :side, String.t()
    field :type, String.t()
    field :order_id, String.t()
    field :transaction_time, DateTime.t()
    field :description, String.t()
    field :status, String.t()
  end

  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      activity_type: data["activity_type"],
      date: parse_date(data["date"]),
      net_amount: parse_decimal(data["net_amount"]),
      symbol: data["symbol"],
      qty: parse_decimal(data["qty"]),
      per_share_amount: parse_decimal(data["per_share_amount"]),
      price: parse_decimal(data["price"]),
      cum_qty: parse_decimal(data["cum_qty"]),
      leaves_qty: parse_decimal(data["leaves_qty"]),
      side: data["side"],
      type: data["type"],
      order_id: data["order_id"],
      transaction_time: parse_datetime(data["transaction_time"]),
      description: data["description"],
      status: data["status"]
    }
  end

  defp parse_decimal(nil), do: nil
  defp parse_decimal(value) when is_binary(value), do: Decimal.new(value)
  defp parse_decimal(value) when is_integer(value), do: Decimal.new(value)
  defp parse_decimal(value) when is_float(value), do: Decimal.from_float(value)

  defp parse_date(nil), do: nil

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
end
