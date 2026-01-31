defmodule Alpa.Trading.WatchlistsTest do
  use ExUnit.Case

  alias Alpa.Error
  alias Alpa.Models.Watchlist
  alias Alpa.Test.MockClient
  alias Alpa.Trading.Watchlists

  setup do
    MockClient.setup()
    on_exit(fn -> MockClient.teardown() end)
    :ok
  end

  @watchlist_data %{
    "id" => "wl-abc-123",
    "account_id" => "account-456",
    "name" => "Tech Stocks",
    "created_at" => "2024-01-10T08:00:00Z",
    "updated_at" => "2024-01-15T12:00:00Z",
    "assets" => [
      %{
        "id" => "asset-1",
        "class" => "us_equity",
        "symbol" => "AAPL",
        "name" => "Apple Inc.",
        "status" => "active",
        "tradable" => true
      },
      %{
        "id" => "asset-2",
        "class" => "us_equity",
        "symbol" => "MSFT",
        "name" => "Microsoft Corp.",
        "status" => "active",
        "tradable" => true
      }
    ]
  }

  describe "list/1" do
    test "requires credentials" do
      result = Watchlists.list(api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a list of watchlists" do
      MockClient.mock_get("/v2/watchlists", {:ok, [@watchlist_data]})

      {:ok, watchlists} = Watchlists.list(api_key: "test", api_secret: "test")

      assert length(watchlists) == 1
      wl = hd(watchlists)
      assert %Watchlist{} = wl
      assert wl.id == "wl-abc-123"
      assert wl.name == "Tech Stocks"
      assert length(wl.assets) == 2
      assert hd(wl.assets).symbol == "AAPL"
    end

    test "handles empty list" do
      MockClient.mock_get("/v2/watchlists", {:ok, []})
      {:ok, watchlists} = Watchlists.list(api_key: "test", api_secret: "test")
      assert watchlists == []
    end

    test "handles invalid response" do
      MockClient.mock_get("/v2/watchlists", {:ok, %{"error" => "unexpected"}})
      {:error, %Error{type: :invalid_response}} = Watchlists.list(api_key: "test", api_secret: "test")
    end
  end

  describe "get/2" do
    test "requires credentials" do
      result = Watchlists.get("wl-abc-123", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "returns a watchlist by ID" do
      MockClient.mock_get("/v2/watchlists/wl-abc-123", {:ok, @watchlist_data})

      {:ok, wl} = Watchlists.get("wl-abc-123", api_key: "test", api_secret: "test")

      assert %Watchlist{} = wl
      assert wl.id == "wl-abc-123"
      assert wl.name == "Tech Stocks"
      assert wl.account_id == "account-456"
      assert wl.created_at != nil
      assert wl.updated_at != nil
    end

    test "handles not found" do
      MockClient.mock_get("/v2/watchlists/nonexistent", {:error, Error.from_response(404, %{"message" => "not found"})})
      {:error, %Error{type: :not_found}} = Watchlists.get("nonexistent", api_key: "test", api_secret: "test")
    end
  end

  describe "create/1" do
    test "requires credentials" do
      result = Watchlists.create(name: "Test", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "creates a watchlist" do
      MockClient.mock_post("/v2/watchlists", {:ok, @watchlist_data})

      {:ok, wl} = Watchlists.create(
        name: "Tech Stocks",
        symbols: ["AAPL", "MSFT"],
        api_key: "test",
        api_secret: "test"
      )

      assert %Watchlist{} = wl
      assert wl.name == "Tech Stocks"
    end

    test "creates a watchlist without symbols" do
      empty_wl = %{@watchlist_data | "assets" => []}
      MockClient.mock_post("/v2/watchlists", {:ok, empty_wl})

      {:ok, wl} = Watchlists.create(
        name: "Empty Watchlist",
        api_key: "test",
        api_secret: "test"
      )

      assert %Watchlist{} = wl
      assert wl.assets == []
    end
  end

  describe "update/2" do
    test "requires credentials" do
      result = Watchlists.update("wl-abc-123", name: "New Name", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "updates a watchlist" do
      updated = %{@watchlist_data | "name" => "Renamed"}
      MockClient.mock_put("/v2/watchlists/wl-abc-123", {:ok, updated})

      {:ok, wl} = Watchlists.update("wl-abc-123",
        name: "Renamed",
        api_key: "test",
        api_secret: "test"
      )

      assert wl.name == "Renamed"
    end
  end

  describe "delete/2" do
    test "requires credentials" do
      result = Watchlists.delete("wl-abc-123", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "deletes a watchlist" do
      MockClient.mock_delete("/v2/watchlists/wl-abc-123", {:ok, :deleted})

      assert {:ok, :deleted} = Watchlists.delete("wl-abc-123", api_key: "test", api_secret: "test")
    end
  end

  describe "add_symbol/3" do
    test "requires credentials" do
      result = Watchlists.add_symbol("wl-abc-123", "NVDA", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "adds a symbol to a watchlist" do
      updated = %{@watchlist_data | "assets" => @watchlist_data["assets"] ++ [
        %{"id" => "asset-3", "class" => "us_equity", "symbol" => "NVDA", "status" => "active", "tradable" => true}
      ]}
      MockClient.mock_post("/v2/watchlists/wl-abc-123", {:ok, updated})

      {:ok, wl} = Watchlists.add_symbol("wl-abc-123", "NVDA", api_key: "test", api_secret: "test")

      assert length(wl.assets) == 3
      assert List.last(wl.assets).symbol == "NVDA"
    end
  end

  describe "remove_symbol/3" do
    test "requires credentials" do
      result = Watchlists.remove_symbol("wl-abc-123", "AAPL", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "removes a symbol from a watchlist (returns updated watchlist)" do
      updated = %{@watchlist_data | "assets" => [Enum.at(@watchlist_data["assets"], 1)]}
      MockClient.mock_delete("/v2/watchlists/wl-abc-123/AAPL", {:ok, updated})

      {:ok, wl} = Watchlists.remove_symbol("wl-abc-123", "AAPL", api_key: "test", api_secret: "test")

      assert %Watchlist{} = wl
      assert length(wl.assets) == 1
    end

    test "removes a symbol from a watchlist (returns :deleted)" do
      MockClient.mock_delete("/v2/watchlists/wl-abc-123/AAPL", {:ok, :deleted})

      {:ok, :deleted} = Watchlists.remove_symbol("wl-abc-123", "AAPL", api_key: "test", api_secret: "test")
    end
  end

  describe "get_by_name/2" do
    test "requires credentials" do
      result = Watchlists.get_by_name("Tech Stocks", api_key: nil, api_secret: nil)
      assert {:error, %Error{type: :missing_credentials}} = result
    end

    test "finds watchlist by name" do
      MockClient.mock_get("/v2/watchlists", {:ok, [@watchlist_data]})

      {:ok, wl} = Watchlists.get_by_name("Tech Stocks", api_key: "test", api_secret: "test")

      assert wl.name == "Tech Stocks"
    end

    test "returns error when watchlist name not found" do
      MockClient.mock_get("/v2/watchlists", {:ok, [@watchlist_data]})

      {:error, %Error{type: :not_found}} = Watchlists.get_by_name("Nonexistent", api_key: "test", api_secret: "test")
    end
  end
end
