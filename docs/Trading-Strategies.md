# Trading Strategies with alpa_ex

## Overview

This guide covers common trading patterns using the alpa_ex SDK against the Alpaca paper trading API. All examples use paper mode by default for safety.

## Setup

```elixir
# Ensure credentials are configured
export APCA_API_KEY_ID="your-key"
export APCA_API_SECRET_KEY="your-secret"
export APCA_USE_PAPER="true"
```

## Strategy 1: Simple Buy-and-Hold

Buy shares and hold until a target price or stop-loss is hit.

```elixir
defmodule Strategy.BuyAndHold do
  def execute(symbol, qty, opts \\ []) do
    take_profit = Keyword.get(opts, :take_profit)
    stop_loss = Keyword.get(opts, :stop_loss)

    # Place a bracket order with take-profit and stop-loss
    order_params = %{
      symbol: symbol,
      qty: qty,
      side: "buy",
      type: "market",
      time_in_force: "day"
    }

    order_params =
      if take_profit && stop_loss do
        Map.merge(order_params, %{
          order_class: "bracket",
          take_profit: %{limit_price: take_profit},
          stop_loss: %{stop_price: stop_loss}
        })
      else
        order_params
      end

    Alpa.Trading.Orders.place(Map.to_list(order_params))
  end
end

# Usage:
# Strategy.BuyAndHold.execute("AAPL", 10, take_profit: "200.00", stop_loss: "170.00")
```

## Strategy 2: Dollar-Cost Averaging

Spread purchases over time to reduce volatility impact.

```elixir
defmodule Strategy.DCA do
  def schedule(symbol, total_amount, num_buys) do
    per_buy = Decimal.div(Decimal.new(total_amount), Decimal.new(num_buys))

    Enum.map(1..num_buys, fn i ->
      # Each buy is a notional (dollar) amount
      {:ok, order} = Alpa.Trading.Orders.place(
        symbol: symbol,
        notional: Decimal.to_string(per_buy),
        side: "buy",
        type: "market",
        time_in_force: "day"
      )
      IO.puts("Buy #{i}/#{num_buys}: Order #{order.id} for $#{per_buy}")
      # In production, you'd schedule these across days/weeks
      Process.sleep(1000)
      order
    end)
  end
end

# Usage:
# Strategy.DCA.schedule("AAPL", "10000", 10)
```

## Strategy 3: Mean Reversion

Buy when price drops below moving average, sell when above.

```elixir
defmodule Strategy.MeanReversion do
  def analyze(symbol, opts \\ []) do
    period = Keyword.get(opts, :period, 20)
    threshold = Keyword.get(opts, :threshold, Decimal.new("0.02"))

    # Fetch historical bars
    {:ok, bars} = Alpa.MarketData.Bars.get(symbol,
      timeframe: "1Day",
      limit: period + 5
    )

    # Calculate simple moving average
    closes = Enum.map(bars, & &1.close)
    sma = calculate_sma(closes, period)

    # Get current price
    {:ok, quote} = Alpa.MarketData.Quotes.latest(symbol)
    current = quote.ask_price

    # Compare to SMA
    deviation = Decimal.div(Decimal.sub(current, sma), sma)

    cond do
      Decimal.compare(deviation, Decimal.negate(threshold)) == :lt ->
        {:buy, symbol, deviation}
      Decimal.compare(deviation, threshold) == :gt ->
        {:sell, symbol, deviation}
      true ->
        {:hold, symbol, deviation}
    end
  end

  defp calculate_sma(prices, period) do
    prices
    |> Enum.take(period)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    |> Decimal.div(Decimal.new(period))
  end
end
```

## Strategy 4: Momentum with Streaming

Use real-time data to detect momentum shifts.

```elixir
defmodule Strategy.Momentum do
  use GenServer

  def start_link(symbols, opts \\ []) do
    GenServer.start_link(__MODULE__, {symbols, opts}, name: __MODULE__)
  end

  def init({symbols, _opts}) do
    # Start market data stream
    {:ok, stream_pid} = Alpa.Stream.MarketData.start_link(
      callback: fn event -> GenServer.cast(__MODULE__, {:market_event, event}) end,
      feed: "iex"
    )

    # Subscribe to trades for our symbols
    Alpa.Stream.MarketData.subscribe(stream_pid, trades: symbols)

    state = %{
      stream_pid: stream_pid,
      symbols: symbols,
      price_history: %{},
      positions: %{}
    }

    {:ok, state}
  end

  def handle_cast({:market_event, %{type: :trade, data: trade}}, state) do
    symbol = trade.symbol
    price = trade.price

    # Track last N prices
    history = Map.get(state.price_history, symbol, [])
    history = [price | Enum.take(history, 19)]

    # Check momentum (5-period vs 20-period)
    if length(history) >= 20 do
      short_avg = avg(Enum.take(history, 5))
      long_avg = avg(history)

      if Decimal.compare(short_avg, long_avg) == :gt do
        # Upward momentum - consider buying
        IO.puts("[Momentum] #{symbol}: bullish crossover #{short_avg} > #{long_avg}")
      end
    end

    {:noreply, put_in(state, [:price_history, symbol], history)}
  end

  defp avg(prices) do
    sum = Enum.reduce(prices, Decimal.new(0), &Decimal.add/2)
    Decimal.div(sum, Decimal.new(length(prices)))
  end
end
```

## Strategy 5: Crypto Arbitrage Monitor

Monitor crypto prices across timeframes.

```elixir
defmodule Strategy.CryptoMonitor do
  def scan(symbols \\ ["BTC/USD", "ETH/USD", "SOL/USD"]) do
    # Get snapshots for all symbols at once
    {:ok, snapshots} = Alpa.Crypto.MarketData.get_snapshots(symbols)

    Enum.each(snapshots, fn {symbol, data} ->
      daily_bar = data["dailyBar"]
      latest = data["latestTrade"]

      if daily_bar && latest do
        open = Decimal.new(daily_bar["o"])
        current = Decimal.new(latest["p"])
        change_pct = Decimal.mult(
          Decimal.div(Decimal.sub(current, open), open),
          Decimal.new(100)
        )

        IO.puts("#{symbol}: $#{current} (#{change_pct}% today)")
      end
    end)
  end
end
```

## Portfolio Management

### Rebalancing

```elixir
defmodule Portfolio.Rebalancer do
  @target_allocations %{
    "AAPL" => Decimal.new("0.30"),
    "MSFT" => Decimal.new("0.25"),
    "GOOGL" => Decimal.new("0.20"),
    "AMZN" => Decimal.new("0.15"),
    "BTC/USD" => Decimal.new("0.10")
  }

  def check_drift do
    {:ok, account} = Alpa.Trading.Account.get()
    {:ok, positions} = Alpa.Trading.Positions.list()
    portfolio_value = account.portfolio_value

    Enum.map(positions, fn pos ->
      target = Map.get(@target_allocations, pos.symbol, Decimal.new(0))
      actual = Decimal.div(pos.market_value, portfolio_value)
      drift = Decimal.sub(actual, target)

      %{
        symbol: pos.symbol,
        target: target,
        actual: actual,
        drift: drift,
        action: if(Decimal.compare(drift, Decimal.new("0.05")) == :gt, do: :sell,
                else: if(Decimal.compare(drift, Decimal.new("-0.05")) == :lt, do: :buy, else: :hold))
      }
    end)
  end
end
```

### Risk Management

```elixir
defmodule Portfolio.Risk do
  def check do
    {:ok, account} = Alpa.Trading.Account.get()
    {:ok, positions} = Alpa.Trading.Positions.list()

    total_exposure = Enum.reduce(positions, Decimal.new(0), fn pos, acc ->
      Decimal.add(acc, Decimal.abs(pos.market_value))
    end)

    concentration = Enum.map(positions, fn pos ->
      weight = Decimal.div(Decimal.abs(pos.market_value), total_exposure)
      {pos.symbol, weight}
    end)
    |> Enum.sort_by(fn {_, w} -> Decimal.to_float(w) end, :desc)

    %{
      equity: account.equity,
      buying_power: account.buying_power,
      total_exposure: total_exposure,
      leverage: Decimal.div(total_exposure, account.equity),
      top_holdings: Enum.take(concentration, 5),
      day_pl: account.equity |> Decimal.sub(account.last_equity)
    }
  end
end
```

## Monitoring with Telemetry

```elixir
# Attach telemetry handlers for trade monitoring
:telemetry.attach_many("trading-monitor", [
  [:alpa, :request, :stop],
  [:alpa, :request, :exception]
], fn
  [:alpa, :request, :stop], %{duration: duration}, %{method: method, path: path}, _config ->
    ms = System.convert_time_unit(duration, :native, :millisecond)
    Logger.info("[API] #{method} #{path} completed in #{ms}ms")

  [:alpa, :request, :exception], %{duration: duration}, %{error: error}, _config ->
    ms = System.convert_time_unit(duration, :native, :millisecond)
    Logger.error("[API] Request failed after #{ms}ms: #{inspect(error)}")
end, nil)
```

## Next Steps

- [ ] Add backtesting framework using historical bars
- [ ] Implement options strategies (covered calls, spreads)
- [ ] Add alerting via webhook/SMS when signals trigger
- [ ] Build LiveView dashboard for real-time monitoring
- [ ] Add position sizing based on Kelly criterion
