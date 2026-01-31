defmodule Alpa.Models.PortfolioHistoryTest do
  use ExUnit.Case, async: true

  alias Alpa.Models.PortfolioHistory

  describe "from_map/1" do
    test "parses complete portfolio history data" do
      data = %{
        "timestamp" => [1_705_276_800, 1_705_363_200, 1_705_449_600],
        "equity" => [100_000.0, 101_500.0, 99_800.0],
        "profit_loss" => [0.0, 1500.0, -200.0],
        "profit_loss_pct" => [0.0, 0.015, -0.002],
        "base_value" => 100_000.0,
        "base_value_asof" => "2024-01-15",
        "timeframe" => "1D"
      }

      history = PortfolioHistory.from_map(data)

      assert history.timestamp == [1_705_276_800, 1_705_363_200, 1_705_449_600]
      assert history.equity == [100_000.0, 101_500.0, 99_800.0]
      assert history.profit_loss == [0.0, 1500.0, -200.0]
      assert history.profit_loss_pct == [0.0, 0.015, -0.002]
      assert history.base_value == 100_000.0
      assert history.base_value_asof == "2024-01-15"
      assert history.timeframe == "1D"
    end

    test "handles nil values" do
      history = PortfolioHistory.from_map(%{})

      assert history.timestamp == nil
      assert history.equity == nil
      assert history.profit_loss == nil
      assert history.profit_loss_pct == nil
      assert history.base_value == nil
      assert history.base_value_asof == nil
      assert history.timeframe == nil
    end

    test "handles equity entries with nil gaps" do
      data = %{
        "timestamp" => [1_705_276_800, 1_705_363_200, 1_705_449_600],
        "equity" => [100_000.0, nil, 99_800.0],
        "profit_loss" => [0.0, nil, -200.0],
        "profit_loss_pct" => [0.0, nil, -0.002]
      }

      history = PortfolioHistory.from_map(data)

      assert Enum.at(history.equity, 1) == nil
      assert Enum.at(history.profit_loss, 1) == nil
      assert Enum.at(history.profit_loss_pct, 1) == nil
    end

    test "handles different timeframes" do
      for tf <- ["1Min", "5Min", "15Min", "1H", "1D"] do
        history = PortfolioHistory.from_map(%{"timeframe" => tf})
        assert history.timeframe == tf
      end
    end
  end
end
