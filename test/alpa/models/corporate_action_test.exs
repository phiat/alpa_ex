defmodule Alpa.Models.CorporateActionTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.CorporateAction

  describe "from_map/1" do
    test "parses dividend announcement" do
      data = %{
        "id" => "ca-div-123",
        "corporate_action_id" => "CA12345",
        "ca_type" => "dividend",
        "ca_sub_type" => "cash",
        "initiating_symbol" => "AAPL",
        "initiating_original_cusip" => "037833100",
        "target_symbol" => "AAPL",
        "target_original_cusip" => "037833100",
        "declaration_date" => "2024-01-10",
        "ex_date" => "2024-01-15",
        "record_date" => "2024-01-16",
        "payable_date" => "2024-02-01",
        "cash" => "0.24",
        "old_rate" => nil,
        "new_rate" => nil
      }

      ca = CorporateAction.from_map(data)

      assert ca.id == "ca-div-123"
      assert ca.corporate_action_id == "CA12345"
      assert ca.ca_type == "dividend"
      assert ca.ca_sub_type == "cash"
      assert ca.initiating_symbol == "AAPL"
      assert ca.initiating_original_cusip == "037833100"
      assert ca.target_symbol == "AAPL"
      assert ca.target_original_cusip == "037833100"
      assert ca.declaration_date == ~D[2024-01-10]
      assert ca.ex_date == ~D[2024-01-15]
      assert ca.record_date == ~D[2024-01-16]
      assert ca.payable_date == ~D[2024-02-01]
      assert Decimal.eq?(ca.cash, Decimal.new("0.24"))
      assert ca.old_rate == nil
      assert ca.new_rate == nil
    end

    test "parses stock split announcement" do
      data = %{
        "id" => "ca-split-456",
        "corporate_action_id" => "CA67890",
        "ca_type" => "split",
        "ca_sub_type" => "forward",
        "initiating_symbol" => "TSLA",
        "declaration_date" => "2024-03-01",
        "ex_date" => "2024-04-01",
        "record_date" => "2024-03-28",
        "old_rate" => "1",
        "new_rate" => "3"
      }

      ca = CorporateAction.from_map(data)

      assert ca.ca_type == "split"
      assert ca.ca_sub_type == "forward"
      assert Decimal.eq?(ca.old_rate, Decimal.new("1"))
      assert Decimal.eq?(ca.new_rate, Decimal.new("3"))
      assert ca.cash == nil
    end

    test "handles nil values" do
      ca = CorporateAction.from_map(%{})

      assert ca.id == nil
      assert ca.ca_type == nil
      assert ca.declaration_date == nil
      assert ca.ex_date == nil
      assert ca.cash == nil
      assert ca.old_rate == nil
      assert ca.new_rate == nil
    end

    test "handles invalid date format" do
      ca = CorporateAction.from_map(%{"ex_date" => "not-a-date"})
      assert ca.ex_date == nil
    end
  end
end
