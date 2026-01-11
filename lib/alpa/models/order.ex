defmodule Alpa.Models.Order do
  @moduledoc """
  Order model for trading operations.
  """
  use TypedStruct

  @type side :: :buy | :sell
  @type order_type :: :market | :limit | :stop | :stop_limit | :trailing_stop
  @type time_in_force :: :day | :gtc | :opg | :cls | :ioc | :fok
  @type order_class :: :simple | :bracket | :oco | :oto
  @type status ::
          :new
          | :partially_filled
          | :filled
          | :done_for_day
          | :canceled
          | :expired
          | :replaced
          | :pending_cancel
          | :pending_replace
          | :pending_new
          | :accepted
          | :accepted_for_bidding
          | :stopped
          | :rejected
          | :suspended
          | :calculated
          | :held

  typedstruct do
    field :id, String.t()
    field :client_order_id, String.t()
    field :created_at, DateTime.t()
    field :updated_at, DateTime.t()
    field :submitted_at, DateTime.t()
    field :filled_at, DateTime.t()
    field :expired_at, DateTime.t()
    field :canceled_at, DateTime.t()
    field :failed_at, DateTime.t()
    field :replaced_at, DateTime.t()
    field :replaced_by, String.t()
    field :replaces, String.t()
    field :asset_id, String.t()
    field :symbol, String.t()
    field :asset_class, String.t()
    field :notional, Decimal.t()
    field :qty, Decimal.t()
    field :filled_qty, Decimal.t()
    field :filled_avg_price, Decimal.t()
    field :order_class, order_class()
    field :order_type, order_type()
    field :type, String.t()
    field :side, side()
    field :time_in_force, time_in_force()
    field :limit_price, Decimal.t()
    field :stop_price, Decimal.t()
    field :trail_percent, Decimal.t()
    field :trail_price, Decimal.t()
    field :hwm, Decimal.t()
    field :status, status()
    field :extended_hours, boolean()
    field :legs, [t()]
  end

  @doc """
  Parse order data from API response.
  """
  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      client_order_id: data["client_order_id"],
      created_at: parse_datetime(data["created_at"]),
      updated_at: parse_datetime(data["updated_at"]),
      submitted_at: parse_datetime(data["submitted_at"]),
      filled_at: parse_datetime(data["filled_at"]),
      expired_at: parse_datetime(data["expired_at"]),
      canceled_at: parse_datetime(data["canceled_at"]),
      failed_at: parse_datetime(data["failed_at"]),
      replaced_at: parse_datetime(data["replaced_at"]),
      replaced_by: data["replaced_by"],
      replaces: data["replaces"],
      asset_id: data["asset_id"],
      symbol: data["symbol"],
      asset_class: data["asset_class"],
      notional: parse_decimal(data["notional"]),
      qty: parse_decimal(data["qty"]),
      filled_qty: parse_decimal(data["filled_qty"]),
      filled_avg_price: parse_decimal(data["filled_avg_price"]),
      order_class: parse_order_class(data["order_class"]),
      order_type: parse_order_type(data["order_type"] || data["type"]),
      type: data["type"],
      side: parse_side(data["side"]),
      time_in_force: parse_time_in_force(data["time_in_force"]),
      limit_price: parse_decimal(data["limit_price"]),
      stop_price: parse_decimal(data["stop_price"]),
      trail_percent: parse_decimal(data["trail_percent"]),
      trail_price: parse_decimal(data["trail_price"]),
      hwm: parse_decimal(data["hwm"]),
      status: parse_status(data["status"]),
      extended_hours: data["extended_hours"],
      legs: parse_legs(data["legs"])
    }
  end

  defp parse_decimal(nil), do: nil
  defp parse_decimal(value) when is_binary(value), do: Decimal.new(value)
  defp parse_decimal(value) when is_integer(value), do: Decimal.new(value)
  defp parse_decimal(value) when is_float(value), do: Decimal.from_float(value)

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp parse_side("buy"), do: :buy
  defp parse_side("sell"), do: :sell
  defp parse_side(_), do: nil

  defp parse_order_type("market"), do: :market
  defp parse_order_type("limit"), do: :limit
  defp parse_order_type("stop"), do: :stop
  defp parse_order_type("stop_limit"), do: :stop_limit
  defp parse_order_type("trailing_stop"), do: :trailing_stop
  defp parse_order_type(_), do: nil

  defp parse_time_in_force("day"), do: :day
  defp parse_time_in_force("gtc"), do: :gtc
  defp parse_time_in_force("opg"), do: :opg
  defp parse_time_in_force("cls"), do: :cls
  defp parse_time_in_force("ioc"), do: :ioc
  defp parse_time_in_force("fok"), do: :fok
  defp parse_time_in_force(_), do: nil

  defp parse_order_class(""), do: :simple
  defp parse_order_class(nil), do: :simple
  defp parse_order_class("simple"), do: :simple
  defp parse_order_class("bracket"), do: :bracket
  defp parse_order_class("oco"), do: :oco
  defp parse_order_class("oto"), do: :oto
  defp parse_order_class(_), do: :simple

  defp parse_status(nil), do: nil
  defp parse_status("new"), do: :new
  defp parse_status("partially_filled"), do: :partially_filled
  defp parse_status("filled"), do: :filled
  defp parse_status("done_for_day"), do: :done_for_day
  defp parse_status("canceled"), do: :canceled
  defp parse_status("expired"), do: :expired
  defp parse_status("replaced"), do: :replaced
  defp parse_status("pending_cancel"), do: :pending_cancel
  defp parse_status("pending_replace"), do: :pending_replace
  defp parse_status("pending_new"), do: :pending_new
  defp parse_status("accepted"), do: :accepted
  defp parse_status("accepted_for_bidding"), do: :accepted_for_bidding
  defp parse_status("stopped"), do: :stopped
  defp parse_status("rejected"), do: :rejected
  defp parse_status("suspended"), do: :suspended
  defp parse_status("calculated"), do: :calculated
  defp parse_status("held"), do: :held

  defp parse_status(other) when is_binary(other) do
    require Logger
    Logger.warning("[Alpa.Models.Order] Unknown order status: #{inspect(other)}")
    nil
  end

  defp parse_legs(nil), do: nil
  defp parse_legs(legs) when is_list(legs), do: Enum.map(legs, &from_map/1)
end
