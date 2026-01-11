defmodule Alpa.Trading.AccountTest do
  use ExUnit.Case, async: true

  alias Alpa.Error
  alias Alpa.Trading.Account

  describe "get/1" do
    test "requires credentials" do
      result = Account.get(api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_configurations/1" do
    test "requires credentials" do
      result = Account.get_configurations(api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "update_configurations/1" do
    test "requires credentials" do
      result = Account.update_configurations(
        suspend_trade: false,
        api_key: nil,
        api_secret: nil
      )

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_activities/1" do
    test "requires credentials" do
      result = Account.get_activities(api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end

  describe "get_portfolio_history/1" do
    test "requires credentials" do
      result = Account.get_portfolio_history(api_key: nil, api_secret: nil)

      assert {:error, %Error{type: :missing_credentials}} = result
    end
  end
end
