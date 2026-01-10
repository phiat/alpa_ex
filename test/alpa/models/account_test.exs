defmodule Alpa.Models.AccountTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Account

  describe "from_map/1" do
    test "parses account data" do
      data = %{
        "id" => "abc-123",
        "account_number" => "123456789",
        "status" => "ACTIVE",
        "currency" => "USD",
        "buying_power" => "100000.00",
        "cash" => "50000.00",
        "portfolio_value" => "150000.00",
        "pattern_day_trader" => false,
        "trading_blocked" => false,
        "transfers_blocked" => false,
        "account_blocked" => false,
        "created_at" => "2024-01-01T00:00:00Z",
        "multiplier" => "4",
        "shorting_enabled" => true,
        "equity" => "150000.00",
        "last_equity" => "148000.00",
        "long_market_value" => "100000.00",
        "short_market_value" => "0",
        "daytrade_count" => 0
      }

      account = Account.from_map(data)

      assert account.id == "abc-123"
      assert account.account_number == "123456789"
      assert account.status == "ACTIVE"
      assert account.currency == "USD"
      assert Decimal.eq?(account.buying_power, Decimal.new("100000.00"))
      assert Decimal.eq?(account.cash, Decimal.new("50000.00"))
      assert account.pattern_day_trader == false
      assert account.shorting_enabled == true
      assert account.daytrade_count == 0
    end

    test "handles nil values" do
      data = %{"id" => "abc-123"}

      account = Account.from_map(data)

      assert account.id == "abc-123"
      assert account.buying_power == nil
      assert account.created_at == nil
    end

    test "parses datetime correctly" do
      data = %{
        "id" => "abc-123",
        "created_at" => "2024-01-15T10:30:00Z"
      }

      account = Account.from_map(data)

      assert account.created_at == ~U[2024-01-15 10:30:00Z]
    end
  end
end
