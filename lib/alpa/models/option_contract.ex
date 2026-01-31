defmodule Alpa.Models.OptionContract do
  @moduledoc """
  Option contract model for options trading.
  """
  use TypedStruct
  import Alpa.Helpers, only: [parse_decimal: 1, parse_date: 1]

  @type option_type :: :call | :put
  @type option_style :: :american | :european

  typedstruct do
    field(:id, String.t())
    field(:symbol, String.t())
    field(:name, String.t())
    field(:status, String.t())
    field(:tradable, boolean())
    field(:expiration_date, Date.t())
    field(:strike_price, Decimal.t())
    field(:type, option_type())
    field(:style, option_style())
    field(:root_symbol, String.t())
    field(:underlying_symbol, String.t())
    field(:underlying_asset_id, String.t())
    field(:open_interest, integer())
    field(:open_interest_date, Date.t())
    field(:close_price, Decimal.t())
    field(:close_price_date, Date.t())
  end

  @doc """
  Parse option contract data from API response.
  """
  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      symbol: data["symbol"],
      name: data["name"],
      status: data["status"],
      tradable: data["tradable"],
      expiration_date: parse_date(data["expiration_date"]),
      strike_price: parse_decimal(data["strike_price"]),
      type: parse_type(data["type"]),
      style: parse_style(data["style"]),
      root_symbol: data["root_symbol"],
      underlying_symbol: data["underlying_symbol"],
      underlying_asset_id: data["underlying_asset_id"],
      open_interest: data["open_interest"],
      open_interest_date: parse_date(data["open_interest_date"]),
      close_price: parse_decimal(data["close_price"]),
      close_price_date: parse_date(data["close_price_date"])
    }
  end

  defp parse_type("call"), do: :call
  defp parse_type("put"), do: :put
  defp parse_type(_), do: nil

  defp parse_style("american"), do: :american
  defp parse_style("european"), do: :european
  defp parse_style(_), do: nil
end
