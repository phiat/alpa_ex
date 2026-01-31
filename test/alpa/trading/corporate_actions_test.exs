defmodule Alpa.Trading.CorporateActionsTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.CorporateAction
  alias Alpa.Test.MockClient
  alias Alpa.Trading.CorporateActions

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @dividend_data %{
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

  @split_data %{
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

  describe "list/1" do
    test "requires credentials" do
      result = CorporateActions.list(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns corporate actions list" do
      MockClient.mock_get(
        "/v2/corporate_actions/announcements",
        {:ok, [@dividend_data, @split_data]}
      )

      {:ok, actions} = CorporateActions.list(api_key: "test", api_secret: "test")

      assert length(actions) == 2
      assert %CorporateAction{} = hd(actions)
      assert hd(actions).ca_type == "dividend"
      assert Enum.at(actions, 1).ca_type == "split"
    end

    test "returns empty list" do
      MockClient.mock_get("/v2/corporate_actions/announcements", {:ok, []})

      {:ok, actions} = CorporateActions.list(api_key: "test", api_secret: "test")

      assert actions == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/corporate_actions/announcements", {:ok, %{"error" => "bad"}})

      {:error, %Error{type: :invalid_response}} =
        CorporateActions.list(api_key: "test", api_secret: "test")
    end

    test "handles API error" do
      MockClient.mock_get(
        "/v2/corporate_actions/announcements",
        {:error, Error.from_response(422, %{"message" => "Invalid params"})}
      )

      {:error, %Error{type: :unprocessable_entity}} =
        CorporateActions.list(api_key: "test", api_secret: "test")
    end
  end

  describe "get/2" do
    test "requires credentials" do
      result = CorporateActions.get("ca-div-123", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a single corporate action" do
      MockClient.mock_get("/v2/corporate_actions/announcements/ca-div-123", {:ok, @dividend_data})

      {:ok, ca} = CorporateActions.get("ca-div-123", api_key: "test", api_secret: "test")

      assert %CorporateAction{} = ca
      assert ca.id == "ca-div-123"
      assert ca.ca_type == "dividend"
      assert ca.ca_sub_type == "cash"
      assert ca.initiating_symbol == "AAPL"
      assert ca.ex_date == ~D[2024-01-15]
      assert Decimal.eq?(ca.cash, Decimal.new("0.24"))
    end

    test "handles not found" do
      MockClient.mock_get(
        "/v2/corporate_actions/announcements/nonexistent",
        {:error, Error.from_response(404, %{"message" => "not found"})}
      )

      {:error, %Error{type: :not_found}} =
        CorporateActions.get("nonexistent", api_key: "test", api_secret: "test")
    end
  end
end
