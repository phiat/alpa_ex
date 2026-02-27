defmodule Alpa.Trading.AccountTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.{Account, AccountConfig, Activity, PortfolioHistory}
  alias Alpa.Test.MockClient
  alias Alpa.Trading.Account, as: TradingAccount

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @account_data %{
    "id" => "account-123",
    "account_number" => "PA123456",
    "status" => "ACTIVE",
    "crypto_status" => "ACTIVE",
    "currency" => "USD",
    "buying_power" => "50000.00",
    "cash" => "25000.00",
    "portfolio_value" => "75000.00",
    "equity" => "75000.00",
    "last_equity" => "74000.00",
    "long_market_value" => "50000.00",
    "short_market_value" => "0",
    "pattern_day_trader" => false,
    "trading_blocked" => false,
    "transfers_blocked" => false,
    "account_blocked" => false,
    "trade_suspended_by_user" => false,
    "multiplier" => "4",
    "shorting_enabled" => true,
    "daytrade_count" => 0,
    "created_at" => "2024-01-01T00:00:00Z"
  }

  @account_config_data %{
    "dtbp_check" => "entry",
    "trade_confirm_email" => "all",
    "suspend_trade" => false,
    "no_shorting" => false,
    "fractional_trading" => true,
    "max_margin_multiplier" => "4",
    "pdt_check" => "entry",
    "ptp_no_exception_entry" => false
  }

  @activity_data %{
    "id" => "activity-001",
    "activity_type" => "FILL",
    "symbol" => "AAPL",
    "qty" => "10",
    "price" => "150.00",
    "side" => "buy",
    "type" => "fill",
    "order_id" => "order-123",
    "transaction_time" => "2024-01-15T14:30:00Z",
    "date" => "2024-01-15"
  }

  @portfolio_history_data %{
    "timestamp" => [1_705_276_800, 1_705_363_200],
    "equity" => [74000.0, 75000.0],
    "profit_loss" => [-1000.0, 0.0],
    "profit_loss_pct" => [-0.0133, 0.0],
    "base_value" => 75000.0,
    "timeframe" => "1D"
  }

  describe "get/1" do
    test "requires credentials" do
      result = TradingAccount.get(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns account information" do
      MockClient.mock_get("/v2/account", {:ok, @account_data})

      {:ok, account} = TradingAccount.get(api_key: "test", api_secret: "test")

      assert %Account{} = account
      assert account.id == "account-123"
      assert account.account_number == "PA123456"
      assert account.status == "ACTIVE"
      assert account.currency == "USD"
      assert Decimal.eq?(account.buying_power, Decimal.new("50000.00"))
      assert Decimal.eq?(account.cash, Decimal.new("25000.00"))
      assert Decimal.eq?(account.portfolio_value, Decimal.new("75000.00"))
      assert account.pattern_day_trader == false
      assert account.trading_blocked == false
      assert account.shorting_enabled == true
      assert account.daytrade_count == 0
    end

    test "handles API error" do
      MockClient.mock_get(
        "/v2/account",
        {:error, Error.from_response(401, %{"message" => "invalid credentials"})}
      )

      {:error, %Error{type: :unauthorized}} =
        TradingAccount.get(api_key: "bad", api_secret: "bad")
    end
  end

  describe "get_configurations/1" do
    test "requires credentials" do
      result = TradingAccount.get_configurations(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns account configurations" do
      MockClient.mock_get("/v2/account/configurations", {:ok, @account_config_data})

      {:ok, config} = TradingAccount.get_configurations(api_key: "test", api_secret: "test")

      assert %AccountConfig{} = config
      assert config.dtbp_check == "entry"
      assert config.trade_confirm_email == "all"
      assert config.suspend_trade == false
      assert config.fractional_trading == true
      assert config.max_margin_multiplier == "4"
    end
  end

  describe "update_configurations/1" do
    test "requires credentials" do
      result =
        TradingAccount.update_configurations(
          suspend_trade: false,
          api_key: nil,
          api_secret: nil
        )

      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "updates account configurations" do
      updated_config = Map.put(@account_config_data, "suspend_trade", true)
      MockClient.mock_patch("/v2/account/configurations", {:ok, updated_config})

      {:ok, config} =
        TradingAccount.update_configurations(
          suspend_trade: true,
          api_key: "test",
          api_secret: "test"
        )

      assert %AccountConfig{} = config
      assert config.suspend_trade == true
    end
  end

  describe "get_activities/1" do
    test "requires credentials" do
      result = TradingAccount.get_activities(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a list of activities" do
      MockClient.mock_get("/v2/account/activities", {:ok, [@activity_data]})

      {:ok, activities} = TradingAccount.get_activities(api_key: "test", api_secret: "test")

      assert length(activities) == 1
      assert %Activity{} = hd(activities)
      assert hd(activities).id == "activity-001"
      assert hd(activities).activity_type == "FILL"
      assert hd(activities).symbol == "AAPL"
      assert Decimal.eq?(hd(activities).qty, Decimal.new("10"))
      assert Decimal.eq?(hd(activities).price, Decimal.new("150.00"))
    end

    test "returns empty list" do
      MockClient.mock_get("/v2/account/activities", {:ok, []})

      {:ok, activities} = TradingAccount.get_activities(api_key: "test", api_secret: "test")
      assert activities == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/account/activities", {:ok, %{"error" => "unexpected"}})

      {:error, %Error{type: :invalid_response}} =
        TradingAccount.get_activities(api_key: "test", api_secret: "test")
    end
  end

  describe "get_activities_by_type/2" do
    test "requires credentials" do
      result = TradingAccount.get_activities_by_type("FILL", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns activities for a specific type" do
      MockClient.mock_get("/v2/account/activities/FILL", {:ok, [@activity_data]})

      {:ok, activities} =
        TradingAccount.get_activities_by_type("FILL", api_key: "test", api_secret: "test")

      assert length(activities) == 1
      assert hd(activities).activity_type == "FILL"
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/account/activities/FILL", {:ok, %{"unexpected" => true}})

      {:error, %Error{type: :invalid_response}} =
        TradingAccount.get_activities_by_type("FILL", api_key: "test", api_secret: "test")
    end
  end

  describe "get_portfolio_history/1" do
    test "requires credentials" do
      result = TradingAccount.get_portfolio_history(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns portfolio history" do
      MockClient.mock_get("/v2/account/portfolio/history", {:ok, @portfolio_history_data})

      {:ok, history} =
        TradingAccount.get_portfolio_history(api_key: "test", api_secret: "test")

      assert %PortfolioHistory{} = history
      assert history.base_value == 75000.0
      assert history.timeframe == "1D"
      assert length(history.timestamp) == 2
      assert length(history.equity) == 2
    end

    test "handles API error" do
      MockClient.mock_get(
        "/v2/account/portfolio/history",
        {:error, Error.from_response(500, %{"message" => "internal error"})}
      )

      {:error, %Error{type: :server_error}} =
        TradingAccount.get_portfolio_history(api_key: "test", api_secret: "test")
    end
  end
end
