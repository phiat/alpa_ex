defmodule Alpa.Models.WatchlistTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.Watchlist

  describe "from_map/1" do
    test "parses complete watchlist data" do
      data = %{
        "id" => "watchlist-123",
        "account_id" => "account-456",
        "name" => "Tech Stocks",
        "created_at" => "2024-01-15T10:30:00Z",
        "updated_at" => "2024-01-16T14:00:00Z",
        "assets" => [
          %{"symbol" => "AAPL", "name" => "Apple Inc.", "class" => "us_equity"},
          %{"symbol" => "MSFT", "name" => "Microsoft Corp.", "class" => "us_equity"}
        ]
      }

      watchlist = Watchlist.from_map(data)

      assert watchlist.id == "watchlist-123"
      assert watchlist.account_id == "account-456"
      assert watchlist.name == "Tech Stocks"
      assert watchlist.created_at == ~U[2024-01-15 10:30:00Z]
      assert watchlist.updated_at == ~U[2024-01-16 14:00:00Z]
      assert length(watchlist.assets) == 2
      assert hd(watchlist.assets).symbol == "AAPL"
    end

    test "handles nil assets" do
      watchlist = Watchlist.from_map(%{"assets" => nil})
      assert watchlist.assets == []
    end

    test "handles empty assets list" do
      watchlist = Watchlist.from_map(%{"assets" => []})
      assert watchlist.assets == []
    end

    test "handles missing assets key" do
      watchlist = Watchlist.from_map(%{"name" => "Test"})
      assert watchlist.assets == []
    end

    test "handles nil values" do
      watchlist = Watchlist.from_map(%{})

      assert watchlist.id == nil
      assert watchlist.account_id == nil
      assert watchlist.name == nil
      assert watchlist.created_at == nil
      assert watchlist.updated_at == nil
      assert watchlist.assets == []
    end

    test "handles invalid datetime" do
      watchlist = Watchlist.from_map(%{
        "created_at" => "not-a-date",
        "updated_at" => "also-not-a-date"
      })

      assert watchlist.created_at == nil
      assert watchlist.updated_at == nil
    end

    test "handles empty string datetime" do
      watchlist = Watchlist.from_map(%{
        "created_at" => "",
        "updated_at" => ""
      })

      assert watchlist.created_at == nil
      assert watchlist.updated_at == nil
    end

    test "parses nested assets correctly" do
      data = %{
        "assets" => [
          %{"symbol" => "AAPL", "tradable" => true, "status" => "active"},
          %{"symbol" => "MSFT", "tradable" => false, "status" => "inactive"}
        ]
      }

      watchlist = Watchlist.from_map(data)

      assert length(watchlist.assets) == 2
      [aapl, msft] = watchlist.assets
      assert aapl.symbol == "AAPL"
      assert aapl.tradable == true
      assert aapl.status == :active
      assert msft.symbol == "MSFT"
      assert msft.tradable == false
      assert msft.status == :inactive
    end
  end
end
