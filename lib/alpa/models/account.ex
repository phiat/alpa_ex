defmodule Alpa.Models.Account do
  @moduledoc """
  Account information model.
  """
  use TypedStruct
  import Alpa.Helpers, only: [parse_decimal: 1, parse_datetime: 1]

  typedstruct do
    field(:id, String.t())
    field(:account_number, String.t())
    field(:status, String.t())
    field(:crypto_status, String.t())
    field(:currency, String.t())
    field(:buying_power, Decimal.t())
    field(:regt_buying_power, Decimal.t())
    field(:daytrading_buying_power, Decimal.t())
    field(:non_marginable_buying_power, Decimal.t())
    field(:cash, Decimal.t())
    field(:accrued_fees, Decimal.t())
    field(:pending_transfer_in, Decimal.t())
    field(:pending_transfer_out, Decimal.t())
    field(:portfolio_value, Decimal.t())
    field(:pattern_day_trader, boolean())
    field(:trading_blocked, boolean())
    field(:transfers_blocked, boolean())
    field(:account_blocked, boolean())
    field(:created_at, DateTime.t())
    field(:trade_suspended_by_user, boolean())
    field(:multiplier, String.t())
    field(:shorting_enabled, boolean())
    field(:equity, Decimal.t())
    field(:last_equity, Decimal.t())
    field(:long_market_value, Decimal.t())
    field(:short_market_value, Decimal.t())
    field(:position_market_value, Decimal.t())
    field(:initial_margin, Decimal.t())
    field(:maintenance_margin, Decimal.t())
    field(:last_maintenance_margin, Decimal.t())
    field(:sma, Decimal.t())
    field(:daytrade_count, integer())
    field(:options_buying_power, Decimal.t())
    field(:options_approved_level, integer())
    field(:options_trading_level, integer())
  end

  @doc """
  Parse account data from API response.
  """
  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      id: data["id"],
      account_number: data["account_number"],
      status: data["status"],
      crypto_status: data["crypto_status"],
      currency: data["currency"],
      buying_power: parse_decimal(data["buying_power"]),
      regt_buying_power: parse_decimal(data["regt_buying_power"]),
      daytrading_buying_power: parse_decimal(data["daytrading_buying_power"]),
      non_marginable_buying_power: parse_decimal(data["non_marginable_buying_power"]),
      cash: parse_decimal(data["cash"]),
      accrued_fees: parse_decimal(data["accrued_fees"]),
      pending_transfer_in: parse_decimal(data["pending_transfer_in"]),
      pending_transfer_out: parse_decimal(data["pending_transfer_out"]),
      portfolio_value: parse_decimal(data["portfolio_value"]),
      pattern_day_trader: data["pattern_day_trader"],
      trading_blocked: data["trading_blocked"],
      transfers_blocked: data["transfers_blocked"],
      account_blocked: data["account_blocked"],
      created_at: parse_datetime(data["created_at"]),
      trade_suspended_by_user: data["trade_suspended_by_user"],
      multiplier: data["multiplier"],
      shorting_enabled: data["shorting_enabled"],
      equity: parse_decimal(data["equity"]),
      last_equity: parse_decimal(data["last_equity"]),
      long_market_value: parse_decimal(data["long_market_value"]),
      short_market_value: parse_decimal(data["short_market_value"]),
      position_market_value: parse_decimal(data["position_market_value"]),
      initial_margin: parse_decimal(data["initial_margin"]),
      maintenance_margin: parse_decimal(data["maintenance_margin"]),
      last_maintenance_margin: parse_decimal(data["last_maintenance_margin"]),
      sma: parse_decimal(data["sma"]),
      daytrade_count: data["daytrade_count"],
      options_buying_power: parse_decimal(data["options_buying_power"]),
      options_approved_level: data["options_approved_level"],
      options_trading_level: data["options_trading_level"]
    }
  end
end
