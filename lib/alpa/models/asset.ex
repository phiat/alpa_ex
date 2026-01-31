defmodule Alpa.Models.Asset do
  @moduledoc """
  Asset information model.
  """
  use TypedStruct
  import Alpa.Helpers, only: [parse_decimal: 1]

  @type status :: :active | :inactive
  @type asset_class :: :us_equity | :crypto

  typedstruct do
    field :id, String.t()
    field :class, asset_class()
    field :exchange, String.t()
    field :symbol, String.t()
    field :name, String.t()
    field :status, status()
    field :tradable, boolean()
    field :marginable, boolean()
    field :maintenance_margin_requirement, Decimal.t()
    field :shortable, boolean()
    field :easy_to_borrow, boolean()
    field :fractionable, boolean()
    field :min_order_size, Decimal.t()
    field :min_trade_increment, Decimal.t()
    field :price_increment, Decimal.t()
  end

  @doc """
  Parse asset data from API response.
  """
  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      class: parse_class(data["class"]),
      exchange: data["exchange"],
      symbol: data["symbol"],
      name: data["name"],
      status: parse_status(data["status"]),
      tradable: data["tradable"],
      marginable: data["marginable"],
      maintenance_margin_requirement: parse_decimal(data["maintenance_margin_requirement"]),
      shortable: data["shortable"],
      easy_to_borrow: data["easy_to_borrow"],
      fractionable: data["fractionable"],
      min_order_size: parse_decimal(data["min_order_size"]),
      min_trade_increment: parse_decimal(data["min_trade_increment"]),
      price_increment: parse_decimal(data["price_increment"])
    }
  end

  defp parse_class("us_equity"), do: :us_equity
  defp parse_class("crypto"), do: :crypto
  defp parse_class(_), do: nil

  defp parse_status("active"), do: :active
  defp parse_status("inactive"), do: :inactive
  defp parse_status(_), do: nil
end
