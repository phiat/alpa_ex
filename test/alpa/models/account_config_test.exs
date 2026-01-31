defmodule Alpa.Models.AccountConfigTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.AccountConfig

  describe "from_map/1" do
    test "parses complete account config data" do
      data = %{
        "dtbp_check" => "both",
        "trade_confirm_email" => "all",
        "suspend_trade" => false,
        "no_shorting" => false,
        "fractional_trading" => true,
        "max_margin_multiplier" => "4",
        "pdt_check" => "entry",
        "ptp_no_exception_entry" => false
      }

      config = AccountConfig.from_map(data)

      assert config.dtbp_check == "both"
      assert config.trade_confirm_email == "all"
      assert config.suspend_trade == false
      assert config.no_shorting == false
      assert config.fractional_trading == true
      assert config.max_margin_multiplier == "4"
      assert config.pdt_check == "entry"
      assert config.ptp_no_exception_entry == false
    end

    test "handles nil values" do
      config = AccountConfig.from_map(%{})

      assert config.dtbp_check == nil
      assert config.trade_confirm_email == nil
      assert config.suspend_trade == nil
      assert config.no_shorting == nil
      assert config.fractional_trading == nil
      assert config.max_margin_multiplier == nil
      assert config.pdt_check == nil
      assert config.ptp_no_exception_entry == nil
    end

    test "parses suspended trade account" do
      data = %{
        "suspend_trade" => true,
        "no_shorting" => true,
        "fractional_trading" => false
      }

      config = AccountConfig.from_map(data)

      assert config.suspend_trade == true
      assert config.no_shorting == true
      assert config.fractional_trading == false
    end
  end
end
