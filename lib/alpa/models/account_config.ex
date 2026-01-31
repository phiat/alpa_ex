defmodule Alpa.Models.AccountConfig do
  @moduledoc """
  Account configuration model.
  """
  use TypedStruct

  typedstruct do
    field(:dtbp_check, String.t())
    field(:trade_confirm_email, String.t())
    field(:suspend_trade, boolean())
    field(:no_shorting, boolean())
    field(:fractional_trading, boolean())
    field(:max_margin_multiplier, String.t())
    field(:pdt_check, String.t())
    field(:ptp_no_exception_entry, boolean())
  end

  @spec from_map(map()) :: t()
  def from_map(data) when is_map(data) do
    %__MODULE__{
      dtbp_check: data["dtbp_check"],
      trade_confirm_email: data["trade_confirm_email"],
      suspend_trade: data["suspend_trade"],
      no_shorting: data["no_shorting"],
      fractional_trading: data["fractional_trading"],
      max_margin_multiplier: data["max_margin_multiplier"],
      pdt_check: data["pdt_check"],
      ptp_no_exception_entry: data["ptp_no_exception_entry"]
    }
  end
end
