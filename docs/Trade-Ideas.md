# Trade Ideas & Strategy Playbook

> **DISCLAIMER:** This document is for educational and paper trading purposes only. Nothing here constitutes financial advice. Penny stocks are highly speculative and carry significant risk of total loss. Always do your own research before risking real capital. All strategies should be validated extensively in paper trading before any live deployment.

## Market Context

As of early 2026, several macro factors shape the trading landscape:

- **Small-cap tailwinds:** Goldman Sachs' portfolio strategy team is optimistic about small-cap upside in early 2026, citing continued Fed easing and inflation remaining below market expectations. This creates a favorable environment for penny stock momentum strategies.
- **Commodity strength:** Precious metals (gold, silver) continue to benefit from geopolitical uncertainty and central bank buying. Agricultural commodities face supply-side pressure from climate disruptions. Energy commodities remain volatile amid the global energy transition.
- **Sector rotation:** Biotech, clean energy, and crypto mining are the dominant penny stock sectors. Infrastructure spending and defense themes continue to generate small-cap opportunities.
- **Algorithmic trading growth:** Platforms like Alpaca have made it easier than ever to deploy systematic strategies via API, with paper trading providing a risk-free testing environment.

---

## Penny Stock Watchlist

These stocks trade under $5 and were selected based on sector momentum, analyst coverage, and fundamental catalysts. Prices are approximate and fluctuate significantly.

| Ticker | Name | Sector | Price Range | Thesis | Risk Level |
|--------|------|--------|-------------|--------|------------|
| BITF | Bitfarms | Crypto Mining | $1.50 - $3.50 | Hydro-powered BTC mining with cost advantage; scales with Bitcoin price | High |
| ABTC | American Bitcoin Corp | Crypto Mining | $1.00 - $4.00 | Top-20 public Bitcoin treasury company with 5,098 BTC in reserves | High |
| CGTX | Cognition Therapeutics | Biotech | $0.50 - $2.50 | Clinical-stage Alzheimer's/Lewy body treatments; binary catalyst from trial data | Very High |
| ANGX | Angel Studios | Entertainment | $2.00 - $4.50 | 25% member growth, 2M+ paying guild members; proven content model | High |
| EVGO | EVgo | Clean Energy/EV | $1.50 - $4.00 | Expanding fast-charging network; 500+ NACS connectors planned; Kroger partnership | High |
| LSF | Laird Superfood | Consumer Goods | $1.00 - $3.00 | Debt-free, short-term assets exceed liabilities; product expansion driving revenue | High |
| ZVIA | Zevia PBC | Consumer/Beverage | $0.80 - $2.50 | Zero-sugar beverage trend; reducing losses; debt-free balance sheet | High |
| GROW | U.S. Global Investors | Financial | $1.50 - $3.50 | $33.95M market cap; profitable with net income of $1.51M; improved earnings | Moderate-High |
| ARBK | Argo Blockchain | Crypto Mining | $0.50 - $2.00 | UK-based BTC miner; high volatility, profitability swings with BTC and energy | Very High |
| OPTX | Syntec Optics | Technology | $1.00 - $3.00 | Precision optics manufacturer; defense and industrial applications | High |

**Key screening criteria used:**
- Trading volume > 500K shares/day (ensures adequate liquidity for entry/exit)
- Market cap > $25M (avoids the most illiquid micro-caps)
- Active analyst coverage or recent institutional interest
- Identifiable catalyst within the next 1-3 months

---

## Commodity ETF Watchlist

These ETFs are tradeable on Alpaca (equities, not futures) and provide exposure to underlying commodity price movements.

| Ticker | Name | Underlying Commodity | Expense Ratio | Thesis |
|--------|------|---------------------|---------------|--------|
| GLD | SPDR Gold Shares | Gold | 0.40% | Safe-haven demand; central bank accumulation; inflation hedge |
| SLV | iShares Silver Trust | Silver | 0.50% | Industrial + precious metal demand; undervalued relative to gold |
| USO | United States Oil Fund | WTI Crude Oil | 0.60% | Energy volatility; geopolitical risk premium; seasonal patterns |
| UNG | United States Natural Gas Fund | Natural Gas | 1.06% | Extreme volatility; seasonal heating/cooling demand swings |
| CORN | Teucrium Corn Fund | Corn Futures | 1.14% | Agricultural supply disruptions; ethanol demand linkage |
| WEAT | Teucrium Wheat Fund | Wheat Futures | 1.14% | Climate-driven supply shocks; geopolitical export disruptions |
| PDBC | Invesco Optimum Yield Diversified Commodity | Broad Commodity Basket | 0.59% | Diversified exposure to 14 commodities; no K-1 tax form |
| GLTR | abrdn Physical Precious Metals Basket | Gold/Silver/Platinum/Palladium | 0.60% | Physical-backed; diversified precious metals exposure |

**Notes:**
- Alpaca does not support direct futures trading. ETFs are the mechanism for commodity exposure.
- Be aware of contango/backwardation effects in futures-based ETFs (USO, UNG especially). These can cause long-term value erosion even if the spot commodity price is flat.
- Agricultural ETFs (CORN, WEAT) tend to have lower liquidity than precious metals ETFs.

---

## Strategy 1: Penny Stock Momentum Scanner

### Concept
Scan penny stocks daily for unusual volume + price momentum. Enter stocks that break above their 5-day high on volume at least 2x the 20-day average. Ride the momentum with a trailing stop.

### Entry Rules
1. Stock is on the penny stock watchlist (or dynamically scanned)
2. Current day's volume is >= 2x the 20-day average daily volume by 10:00 AM ET
3. Price breaks above the 5-day high
4. Price is above the 10-period EMA on 15-minute bars
5. Spread is < 2% of the stock price (liquidity filter)

### Exit Rules
- **Take profit:** Scale out 1/3 at +15%, 1/3 at +30%, trail the rest
- **Stop loss:** 10% below entry price (hard stop)
- **Trailing stop:** After +15% gain, trail at 8% below the high watermark
- **Time stop:** Close any remaining position by 3:45 PM ET (avoid overnight gap risk)

### Position Sizing
- Max 2% of portfolio per penny stock trade
- Max 3 penny stock positions open simultaneously (6% total exposure)
- Never more than 10% of portfolio in penny stocks total

### alpa_ex Code Example

```elixir
defmodule Strategy.PennyMomentum do
  @moduledoc """
  Penny stock momentum scanner and trader.
  Scans watchlist for volume + price breakouts and enters bracket orders.
  """

  alias Alpa.MarketData.{Bars, Snapshots}
  alias Alpa.Trading.{Orders, Positions, Account}

  @watchlist ["BITF", "ABTC", "CGTX", "ANGX", "EVGO", "LSF", "ZVIA", "GROW", "ARBK", "OPTX"]
  @volume_multiplier 2.0
  @max_risk_per_trade 0.02
  @stop_loss_pct 0.10
  @take_profit_pct 0.15
  @max_open_positions 3

  def scan_and_trade do
    with {:ok, account} <- Account.get(),
         {:ok, positions} <- Positions.list() do

      buying_power = parse_float(account.buying_power)
      equity = parse_float(account.equity)
      open_penny_count = Enum.count(positions, &(&1.symbol in @watchlist))

      if open_penny_count >= @max_open_positions do
        IO.puts("Max penny positions reached (#{open_penny_count}). Skipping scan.")
        :max_positions
      else
        scan_watchlist(equity, buying_power)
      end
    end
  end

  defp scan_watchlist(equity, buying_power) do
    Enum.each(@watchlist, fn symbol ->
      with {:ok, bars_20d} <- Bars.get(symbol, timeframe: "1Day", limit: 20),
           {:ok, snapshot} <- Snapshots.get(symbol) do

        avg_volume = calculate_avg_volume(bars_20d)
        five_day_high = calculate_five_day_high(bars_20d)
        current_price = parse_float(snapshot.daily_bar.close)
        current_volume = snapshot.daily_bar.volume

        cond do
          current_volume >= avg_volume * @volume_multiplier and
          current_price > five_day_high ->
            IO.puts("SIGNAL: #{symbol} breaking out! Price: #{current_price}, Vol: #{current_volume}")
            place_momentum_trade(symbol, current_price, equity, buying_power)

          true ->
            IO.puts("No signal for #{symbol}. Price: #{current_price}, 5d-high: #{five_day_high}")
        end
      else
        {:error, err} ->
          IO.puts("Error scanning #{symbol}: #{inspect(err)}")
      end
    end)
  end

  defp place_momentum_trade(symbol, price, equity, buying_power) do
    risk_amount = equity * @max_risk_per_trade
    stop_price = Float.round(price * (1 - @stop_loss_pct), 2)
    take_profit_price = Float.round(price * (1 + @take_profit_pct), 2)
    risk_per_share = price - stop_price
    qty = min(trunc(risk_amount / risk_per_share), trunc(buying_power / price))

    if qty > 0 do
      case Orders.place(
        symbol: symbol,
        qty: qty,
        side: "buy",
        type: "market",
        time_in_force: "day",
        order_class: "bracket",
        take_profit: %{limit_price: to_string(take_profit_price)},
        stop_loss: %{stop_price: to_string(stop_price)}
      ) do
        {:ok, order} ->
          IO.puts("ORDER PLACED: #{symbol} qty=#{qty} stop=#{stop_price} tp=#{take_profit_price}")
          {:ok, order}
        {:error, err} ->
          IO.puts("ORDER FAILED: #{symbol} - #{inspect(err)}")
          {:error, err}
      end
    else
      IO.puts("Insufficient size for #{symbol} at #{price}")
      :insufficient_size
    end
  end

  defp calculate_avg_volume(bars) do
    bars
    |> Enum.map(& &1.volume)
    |> then(fn vols ->
      Enum.sum(vols) / max(length(vols), 1)
    end)
  end

  defp calculate_five_day_high(bars) do
    bars
    |> Enum.take(-5)
    |> Enum.map(&parse_float(&1.high))
    |> Enum.max(fn -> 0.0 end)
  end

  defp parse_float(val) when is_binary(val), do: String.to_float(val)
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val / 1.0
  defp parse_float(_), do: 0.0
end
```

### Risk Warnings
- Penny stocks can gap 20-50% overnight. The time stop at 3:45 PM is critical.
- Bracket orders may not fill the stop leg in fast-moving, illiquid markets. Slippage can be severe.
- Volume spikes in penny stocks can be driven by pump-and-dump schemes. Verify the catalyst is legitimate before trading.
- Paper trading will not accurately simulate penny stock slippage. Expect 2-5x worse fills in live trading.

---

## Strategy 2: Commodity ETF Mean Reversion

### Concept
Commodity ETFs tend to revert to their moving average after short-term extremes. When RSI drops below 30 (oversold) or rises above 70 (overbought) on daily bars, fade the move with a target back toward the 20-day SMA.

### Entry Rules
1. Compute 14-day RSI from daily closing prices
2. **Long entry:** RSI < 30 AND price is within 2% of the lower Bollinger Band (20-day, 2 std dev)
3. **Short entry (sell existing position):** RSI > 70 AND price is within 2% of the upper Bollinger Band
4. Confirm with volume: current volume should be > 1.5x the 10-day average (exhaustion signal)

### Exit Rules
- **Take profit:** Price returns to the 20-day SMA (the "mean")
- **Stop loss:** 5% beyond the entry (i.e., if long at oversold, stop 5% below entry)
- **Time stop:** Close after 10 trading days if neither target nor stop is hit

### Position Sizing
- Max 5% of portfolio per commodity ETF trade
- Max 20% of portfolio in commodity ETFs total
- Scale position inversely with volatility (use ATR): larger positions in low-ATR ETFs like GLD, smaller in high-ATR ETFs like UNG

### alpa_ex Code Example

```elixir
defmodule Strategy.CommodityMeanReversion do
  @moduledoc """
  Mean reversion strategy for commodity ETFs.
  Enters when RSI hits extremes, targets the 20-day SMA.
  """

  alias Alpa.MarketData.Bars
  alias Alpa.Trading.{Orders, Positions, Account}

  @etf_watchlist ["GLD", "SLV", "USO", "UNG", "CORN", "WEAT", "PDBC", "GLTR"]
  @rsi_period 14
  @sma_period 20
  @rsi_oversold 30
  @rsi_overbought 70
  @stop_loss_pct 0.05
  @max_risk_per_trade 0.05

  def scan_mean_reversion do
    with {:ok, account} <- Account.get() do
      equity = parse_float(account.equity)

      Enum.each(@etf_watchlist, fn symbol ->
        case Bars.get(symbol, timeframe: "1Day", limit: 50, adjustment: "split") do
          {:ok, bars} when length(bars) >= @sma_period ->
            analyze_and_trade(symbol, bars, equity)
          {:ok, _} ->
            IO.puts("Insufficient data for #{symbol}")
          {:error, err} ->
            IO.puts("Error fetching #{symbol}: #{inspect(err)}")
        end
      end)
    end
  end

  defp analyze_and_trade(symbol, bars, equity) do
    closes = Enum.map(bars, &parse_float(&1.close))
    rsi = calculate_rsi(closes, @rsi_period)
    sma_20 = calculate_sma(closes, @sma_period)
    current_price = List.last(closes)
    {lower_bb, upper_bb} = calculate_bollinger(closes, @sma_period, 2.0)

    cond do
      rsi < @rsi_oversold and current_price <= lower_bb * 1.02 ->
        IO.puts("OVERSOLD SIGNAL: #{symbol} RSI=#{Float.round(rsi, 1)} Price=#{current_price}")
        target = Float.round(sma_20, 2)
        enter_long(symbol, current_price, target, equity)

      rsi > @rsi_overbought and current_price >= upper_bb * 0.98 ->
        IO.puts("OVERBOUGHT SIGNAL: #{symbol} RSI=#{Float.round(rsi, 1)} - Consider exiting longs")
        maybe_exit_position(symbol)

      true ->
        IO.puts("#{symbol}: RSI=#{Float.round(rsi, 1)}, Price=#{current_price}, SMA=#{Float.round(sma_20, 2)} - No signal")
    end
  end

  defp enter_long(symbol, price, target, equity) do
    stop_price = Float.round(price * (1 - @stop_loss_pct), 2)
    risk_amount = equity * @max_risk_per_trade
    risk_per_share = price - stop_price
    qty = trunc(risk_amount / risk_per_share)

    if qty > 0 do
      case Orders.place(
        symbol: symbol,
        qty: qty,
        side: "buy",
        type: "market",
        time_in_force: "day",
        order_class: "bracket",
        take_profit: %{limit_price: to_string(target)},
        stop_loss: %{stop_price: to_string(stop_price)}
      ) do
        {:ok, order} ->
          IO.puts("LONG #{symbol}: qty=#{qty} target=#{target} stop=#{stop_price}")
          {:ok, order}
        {:error, err} ->
          IO.puts("ORDER FAILED for #{symbol}: #{inspect(err)}")
          {:error, err}
      end
    end
  end

  defp maybe_exit_position(symbol) do
    case Positions.get(symbol) do
      {:ok, position} ->
        IO.puts("Closing overbought position in #{symbol}")
        Positions.close(symbol)
      {:error, _} ->
        IO.puts("No position in #{symbol} to close")
    end
  end

  # --- Technical Indicator Calculations ---

  defp calculate_rsi(closes, period) do
    changes = closes |> Enum.chunk_every(2, 1, :discard) |> Enum.map(fn [a, b] -> b - a end)
    recent = Enum.take(changes, -period)
    gains = recent |> Enum.filter(&(&1 > 0)) |> Enum.sum()
    losses = recent |> Enum.filter(&(&1 < 0)) |> Enum.map(&abs/1) |> Enum.sum()
    avg_gain = gains / period
    avg_loss = losses / period

    if avg_loss == 0, do: 100.0, else: 100.0 - 100.0 / (1.0 + avg_gain / avg_loss)
  end

  defp calculate_sma(closes, period) do
    closes |> Enum.take(-period) |> then(&(Enum.sum(&1) / length(&1)))
  end

  defp calculate_bollinger(closes, period, num_std) do
    recent = Enum.take(closes, -period)
    sma = Enum.sum(recent) / length(recent)
    variance = Enum.map(recent, fn x -> (x - sma) * (x - sma) end) |> Enum.sum() |> Kernel./(length(recent))
    std_dev = :math.sqrt(variance)
    {sma - num_std * std_dev, sma + num_std * std_dev}
  end

  defp parse_float(val) when is_binary(val), do: String.to_float(val)
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val / 1.0
  defp parse_float(_), do: 0.0
end
```

### Risk Warnings
- Mean reversion fails in trending markets. If a commodity is in a strong trend, "oversold" can stay oversold for weeks.
- UNG (natural gas) is particularly dangerous for mean reversion due to extreme trending behavior.
- Futures-based ETFs suffer from roll yield. A mean reversion to the SMA may not reflect actual commodity price behavior.
- Always check the economic calendar for USDA reports (agriculture), OPEC meetings (oil), and Fed announcements (gold) before entering trades.

---

## Strategy 3: Penny Stock Breakout Hunter

### Concept
Identify penny stocks consolidating in a tight range (low ATR relative to price), then enter on a volume-confirmed breakout above the consolidation range. This captures the transition from accumulation to markup.

### Entry Rules
1. Stock has been trading in a range where (High - Low) / Close < 15% over the past 10 days
2. Today's volume is > 3x the 10-day average volume
3. Price breaks above the 10-day high on an intraday basis
4. The breakout candle's body (|close - open|) is > 50% of the total range (|high - low|) -- a "real" candle, not a doji

### Exit Rules
- **Take profit #1:** +20% from entry (sell 50% of position)
- **Take profit #2:** +40% from entry (sell remaining 50%)
- **Stop loss:** Below the consolidation low (the 10-day low), max 15% below entry
- **Failed breakout exit:** If price closes back inside the consolidation range within 2 days, close immediately

### Position Sizing
- Max 1.5% of portfolio risk per trade
- Calculate position size: (Portfolio * 0.015) / (Entry - Stop)
- Never hold more than 4 breakout positions simultaneously

### alpa_ex Code Example

```elixir
defmodule Strategy.BreakoutHunter do
  @moduledoc """
  Identifies penny stocks breaking out of consolidation ranges
  with volume confirmation.
  """

  alias Alpa.MarketData.{Bars, Snapshots}
  alias Alpa.Trading.{Orders, Account}

  @watchlist ["BITF", "ABTC", "CGTX", "ANGX", "EVGO", "LSF", "ZVIA", "GROW", "ARBK", "OPTX"]
  @consolidation_days 10
  @range_threshold 0.15
  @volume_multiplier 3.0
  @risk_per_trade 0.015

  def scan_breakouts do
    with {:ok, account} <- Account.get() do
      equity = parse_float(account.equity)

      results =
        @watchlist
        |> Enum.map(fn symbol ->
          case detect_breakout(symbol) do
            {:breakout, data} -> {symbol, data}
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      IO.puts("Found #{length(results)} breakout candidates")

      Enum.each(results, fn {symbol, data} ->
        place_breakout_trade(symbol, data, equity)
      end)
    end
  end

  defp detect_breakout(symbol) do
    with {:ok, bars} <- Bars.get(symbol, timeframe: "1Day", limit: @consolidation_days + 1),
         {:ok, snapshot} <- Snapshots.get(symbol) do

      recent_bars = Enum.take(bars, -@consolidation_days)
      highs = Enum.map(recent_bars, &parse_float(&1.high))
      lows = Enum.map(recent_bars, &parse_float(&1.low))
      volumes = Enum.map(recent_bars, & &1.volume)

      range_high = Enum.max(highs)
      range_low = Enum.min(lows)
      avg_close = Enum.map(recent_bars, &parse_float(&1.close)) |> then(&(Enum.sum(&1) / length(&1)))
      range_pct = (range_high - range_low) / avg_close
      avg_volume = Enum.sum(volumes) / length(volumes)

      current_price = parse_float(snapshot.daily_bar.close)
      current_volume = snapshot.daily_bar.volume

      is_tight_range = range_pct < @range_threshold
      is_volume_spike = current_volume >= avg_volume * @volume_multiplier
      is_breaking_out = current_price > range_high

      if is_tight_range and is_volume_spike and is_breaking_out do
        {:breakout, %{
          price: current_price,
          range_high: range_high,
          range_low: range_low,
          volume_ratio: current_volume / avg_volume
        }}
      else
        :no_signal
      end
    else
      _ -> :error
    end
  end

  defp place_breakout_trade(symbol, data, equity) do
    stop_price = max(data.range_low, data.price * 0.85) |> Float.round(2)
    tp1 = Float.round(data.price * 1.20, 2)
    risk_per_share = data.price - stop_price
    risk_amount = equity * @risk_per_trade
    qty = trunc(risk_amount / risk_per_share)

    if qty > 0 do
      # Place bracket order with first take-profit target
      case Orders.place(
        symbol: symbol,
        qty: qty,
        side: "buy",
        type: "market",
        time_in_force: "day",
        order_class: "bracket",
        take_profit: %{limit_price: to_string(tp1)},
        stop_loss: %{stop_price: to_string(stop_price)}
      ) do
        {:ok, order} ->
          IO.puts("""
          BREAKOUT TRADE: #{symbol}
            Entry: ~#{data.price}
            Stop: #{stop_price} (below consolidation low)
            TP1: #{tp1} (+20%)
            Qty: #{qty}
            Volume ratio: #{Float.round(data.volume_ratio, 1)}x
          """)
          {:ok, order}
        {:error, err} ->
          IO.puts("Failed to enter #{symbol}: #{inspect(err)}")
          {:error, err}
      end
    end
  end

  defp parse_float(val) when is_binary(val), do: String.to_float(val)
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val / 1.0
  defp parse_float(_), do: 0.0
end
```

### Risk Warnings
- Failed breakouts are common in penny stocks. The 2-day "close back inside range" rule is essential.
- Volume spikes without fundamental catalysts are often pump-and-dump setups. Cross-reference with news before entering.
- Tight consolidation ranges in penny stocks can also indicate dying interest / delisting risk. Verify the company is still operational.
- Penny stock breakouts are most reliable in the first 2 hours of the trading day. Late-day breakouts frequently reverse.

---

## Strategy 4: Gold/Silver Ratio Trade

### Concept
The Gold/Silver ratio (GLD price / SLV price as a proxy) oscillates in a historical range. When the ratio is at extremes, mean-revert by going long the undervalued metal and short (or underweighting) the overvalued one. This is a relative value / pairs trade.

### Historical Context
- The Gold/Silver ratio historically ranges from 40 to 90
- Above 80: Silver is historically undervalued relative to gold
- Below 50: Gold is historically undervalued relative to silver
- The ratio tends to compress during precious metals bull markets

### Entry Rules
1. Calculate the ratio: GLD_price / SLV_price (normalized by share price, not oz price)
2. Compute 60-day SMA and standard deviation of the ratio
3. **Long silver / short gold:** Ratio > SMA + 1.5 standard deviations (silver undervalued)
4. **Long gold / short silver:** Ratio < SMA - 1.5 standard deviations (gold undervalued)
5. For a simpler version (long-only): just shift allocation between GLD and SLV based on the ratio

### Exit Rules
- **Take profit:** Ratio returns to the 60-day SMA
- **Stop loss:** Ratio moves 2.5 standard deviations from the mean (the divergence is widening, not converging)
- **Time stop:** Close after 30 trading days

### Position Sizing
- Total position: 10% of portfolio split between GLD and SLV
- Long-only variant: When ratio is high (silver cheap), allocate 70% SLV / 30% GLD. When ratio is low (gold cheap), allocate 70% GLD / 30% SLV. Neutral: 50/50.

### alpa_ex Code Example

```elixir
defmodule Strategy.GoldSilverRatio do
  @moduledoc """
  Pairs trade on the Gold/Silver ratio using GLD and SLV ETFs.
  Shifts allocation when the ratio hits statistical extremes.
  """

  alias Alpa.MarketData.Bars
  alias Alpa.Trading.{Orders, Positions, Account}

  @ratio_lookback 60
  @entry_z_score 1.5
  @stop_z_score 2.5
  @target_allocation 0.10  # 10% of portfolio

  def analyze_and_rebalance do
    with {:ok, account} <- Account.get(),
         {:ok, gld_bars} <- Bars.get("GLD", timeframe: "1Day", limit: @ratio_lookback),
         {:ok, slv_bars} <- Bars.get("SLV", timeframe: "1Day", limit: @ratio_lookback) do

      equity = parse_float(account.equity)
      allocation = equity * @target_allocation

      gld_closes = Enum.map(gld_bars, &parse_float(&1.close))
      slv_closes = Enum.map(slv_bars, &parse_float(&1.close))

      # Calculate ratio series (GLD / SLV)
      ratios =
        Enum.zip(gld_closes, slv_closes)
        |> Enum.map(fn {g, s} -> if s > 0, do: g / s, else: 0.0 end)

      current_ratio = List.last(ratios)
      sma = Enum.sum(ratios) / length(ratios)
      variance = Enum.map(ratios, fn r -> (r - sma) * (r - sma) end) |> Enum.sum() |> Kernel./(length(ratios))
      std_dev = :math.sqrt(variance)
      z_score = if std_dev > 0, do: (current_ratio - sma) / std_dev, else: 0.0

      current_gld = List.last(gld_closes)
      current_slv = List.last(slv_closes)

      IO.puts("""
      Gold/Silver Ratio Analysis:
        Current ratio: #{Float.round(current_ratio, 2)}
        60-day SMA: #{Float.round(sma, 2)}
        Z-score: #{Float.round(z_score, 2)}
        GLD: $#{current_gld}, SLV: $#{current_slv}
      """)

      cond do
        z_score > @entry_z_score ->
          # Silver undervalued -> overweight SLV
          IO.puts("SIGNAL: Silver undervalued (z=#{Float.round(z_score, 2)}). Overweighting SLV.")
          rebalance_to(allocation, 0.30, 0.70, current_gld, current_slv)

        z_score < -@entry_z_score ->
          # Gold undervalued -> overweight GLD
          IO.puts("SIGNAL: Gold undervalued (z=#{Float.round(z_score, 2)}). Overweighting GLD.")
          rebalance_to(allocation, 0.70, 0.30, current_gld, current_slv)

        abs(z_score) < 0.5 ->
          # Neutral zone -> equal weight
          IO.puts("NEUTRAL: Ratio near mean. Equal weighting.")
          rebalance_to(allocation, 0.50, 0.50, current_gld, current_slv)

        true ->
          IO.puts("No action. Z-score between thresholds.")
      end
    end
  end

  defp rebalance_to(allocation, gld_weight, slv_weight, gld_price, slv_price) do
    target_gld_qty = trunc(allocation * gld_weight / gld_price)
    target_slv_qty = trunc(allocation * slv_weight / slv_price)

    # Close existing positions first, then enter new ones
    close_if_exists("GLD")
    close_if_exists("SLV")

    # Small delay would be needed in production; paper trading is instant
    if target_gld_qty > 0 do
      Orders.buy("GLD", target_gld_qty)
      |> log_order("GLD", target_gld_qty)
    end

    if target_slv_qty > 0 do
      Orders.buy("SLV", target_slv_qty)
      |> log_order("SLV", target_slv_qty)
    end
  end

  defp close_if_exists(symbol) do
    case Positions.get(symbol) do
      {:ok, _pos} -> Positions.close(symbol)
      {:error, _} -> :no_position
    end
  end

  defp log_order(result, symbol, qty) do
    case result do
      {:ok, order} -> IO.puts("  Bought #{qty} shares of #{symbol}")
      {:error, err} -> IO.puts("  Failed to buy #{symbol}: #{inspect(err)}")
    end
  end

  defp parse_float(val) when is_binary(val), do: String.to_float(val)
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val / 1.0
  defp parse_float(_), do: 0.0
end
```

### Risk Warnings
- The GLD/SLV price ratio is not identical to the gold/silver ounce ratio due to different share structures. Use it as a proxy, not an exact measure.
- Precious metals can trend for months. A mean-reversion approach on the ratio can suffer extended drawdowns during secular trends.
- This strategy has relatively low turnover. It may sit in a position for weeks. That is by design -- do not over-trade it.
- Central bank policy changes can cause regime shifts in the ratio. Monitor Fed announcements closely.

---

## Strategy 5: Multi-Asset Momentum Portfolio

### Concept
A portfolio-level strategy that rotates capital among penny stocks, commodity ETFs, and large-cap sector ETFs based on 1-month momentum (rate of change). Hold the top-performing assets and rebalance weekly. This captures cross-asset momentum while diversifying across uncorrelated markets.

### Universe
- **Penny stocks:** BITF, ABTC, ANGX, EVGO, GROW
- **Commodity ETFs:** GLD, SLV, USO, PDBC
- **Sector ETFs (large-cap anchors):** SPY, QQQ, XLE, XLF

### Entry Rules (Weekly Rebalance)
1. Every Monday at 10:00 AM ET, calculate 20-day rate of change (ROC) for all assets in the universe
2. Rank all assets by ROC descending
3. Buy the top 5 assets
4. If any top-5 asset is a penny stock, cap its allocation at 3% of portfolio
5. Remaining allocation is split equally among the other selected assets

### Exit Rules
- **Rebalance exit:** Any asset falling out of the top 5 is sold at the next weekly rebalance
- **Emergency stop:** If any single position loses > 12% from entry between rebalances, close it immediately
- **Cash filter:** If SPY's 20-day ROC is negative and SPY is below its 50-day SMA, move 50% of portfolio to cash (risk-off)

### Position Sizing
- Equal weight among top 5 (20% each), except penny stocks capped at 3%
- Excess allocation from penny stock caps is redistributed to the next-ranked asset
- Maximum portfolio utilization: 90% (keep 10% cash buffer)

### alpa_ex Code Example

```elixir
defmodule Strategy.MultiAssetMomentum do
  @moduledoc """
  Cross-asset momentum rotation portfolio.
  Selects top-5 assets weekly from a universe spanning penny stocks,
  commodity ETFs, and sector ETFs.
  """

  alias Alpa.MarketData.Bars
  alias Alpa.Trading.{Orders, Positions, Account}

  @universe %{
    penny: ["BITF", "ABTC", "ANGX", "EVGO", "GROW"],
    commodity: ["GLD", "SLV", "USO", "PDBC"],
    sector: ["SPY", "QQQ", "XLE", "XLF"]
  }
  @top_n 5
  @roc_period 20
  @penny_max_weight 0.03
  @emergency_stop 0.12
  @cash_buffer 0.10

  def weekly_rebalance do
    with {:ok, account} <- Account.get() do
      equity = parse_float(account.equity)
      all_symbols = Enum.flat_map(Map.values(@universe), & &1)

      # Compute momentum for all symbols
      rankings =
        all_symbols
        |> Enum.map(fn symbol ->
          case Bars.get(symbol, timeframe: "1Day", limit: @roc_period + 1, adjustment: "split") do
            {:ok, bars} when length(bars) > @roc_period ->
              closes = Enum.map(bars, &parse_float(&1.close))
              old_price = List.first(closes)
              new_price = List.last(closes)
              roc = if old_price > 0, do: (new_price - old_price) / old_price * 100, else: 0.0
              {symbol, roc, new_price}
            _ ->
              {symbol, -999.0, 0.0}
          end
        end)
        |> Enum.sort_by(fn {_sym, roc, _price} -> roc end, :desc)

      # Check risk-off filter (SPY below 50-day SMA with negative ROC)
      risk_off = check_risk_off()

      IO.puts("\n--- Multi-Asset Momentum Rankings ---")
      Enum.each(rankings, fn {sym, roc, price} ->
        IO.puts("  #{String.pad_trailing(sym, 6)} ROC: #{Float.round(roc, 2)}%  Price: $#{price}")
      end)

      # Select top N
      selected = Enum.take(rankings, @top_n)
      usable_equity = equity * (1 - @cash_buffer) * (if risk_off, do: 0.5, else: 1.0)

      if risk_off, do: IO.puts("\nRISK-OFF: SPY filter active. Using 50% allocation.")

      # Calculate target allocations
      allocations = compute_allocations(selected, usable_equity)

      # Close positions not in the new selection
      close_stale_positions(selected)

      # Enter new positions
      Enum.each(allocations, fn {symbol, qty, dollar_amt} ->
        if qty > 0 do
          case Orders.buy(symbol, qty) do
            {:ok, _} ->
              IO.puts("  BUY #{qty} #{symbol} (~$#{Float.round(dollar_amt, 0)})")
            {:error, err} ->
              IO.puts("  FAILED #{symbol}: #{inspect(err)}")
          end
        end
      end)
    end
  end

  defp compute_allocations(selected, usable_equity) do
    penny_symbols = @universe.penny
    base_weight = 1.0 / length(selected)

    # First pass: cap penny stocks
    {capped, excess} =
      Enum.reduce(selected, {[], 0.0}, fn {symbol, _roc, price}, {acc, excess} ->
        is_penny = symbol in penny_symbols
        weight = if is_penny, do: min(base_weight, @penny_max_weight), else: base_weight
        freed = if is_penny and base_weight > @penny_max_weight, do: base_weight - @penny_max_weight, else: 0.0
        {[{symbol, weight, price} | acc], excess + freed}
      end)

    # Second pass: redistribute excess to non-penny positions
    non_penny_count = Enum.count(capped, fn {sym, _, _} -> sym not in penny_symbols end)
    bonus = if non_penny_count > 0, do: excess / non_penny_count, else: 0.0

    capped
    |> Enum.reverse()
    |> Enum.map(fn {symbol, weight, price} ->
      final_weight = if symbol not in penny_symbols, do: weight + bonus, else: weight
      dollar_amt = usable_equity * final_weight
      qty = if price > 0, do: trunc(dollar_amt / price), else: 0
      {symbol, qty, dollar_amt}
    end)
  end

  defp close_stale_positions(selected) do
    selected_symbols = Enum.map(selected, fn {sym, _, _} -> sym end)

    case Positions.list() do
      {:ok, positions} ->
        positions
        |> Enum.filter(&(&1.symbol not in selected_symbols))
        |> Enum.each(fn pos ->
          IO.puts("  Closing stale position: #{pos.symbol}")
          Positions.close(pos.symbol)
        end)
      _ -> :ok
    end
  end

  defp check_risk_off do
    case Bars.get("SPY", timeframe: "1Day", limit: 51, adjustment: "split") do
      {:ok, bars} when length(bars) >= 50 ->
        closes = Enum.map(bars, &parse_float(&1.close))
        current = List.last(closes)
        sma_50 = Enum.take(closes, -50) |> then(&(Enum.sum(&1) / length(&1)))
        old = Enum.at(closes, -21, current)
        roc_20 = (current - old) / old * 100
        current < sma_50 and roc_20 < 0
      _ ->
        false
    end
  end

  defp parse_float(val) when is_binary(val), do: String.to_float(val)
  defp parse_float(val) when is_float(val), do: val
  defp parse_float(val) when is_integer(val), do: val / 1.0
  defp parse_float(_), do: 0.0
end
```

### Risk Warnings
- Momentum strategies suffer during market regime changes (trend reversals). The SPY risk-off filter mitigates this but does not eliminate it.
- Penny stocks in a momentum portfolio can introduce extreme tail risk. The 3% cap is critical -- do not override it.
- Weekly rebalancing creates tax events. In a taxable account, be aware of wash sale rules when rotating in and out of the same positions.
- Past momentum does not guarantee future performance. This strategy will have drawdown periods of 10-20% during market corrections.
- Transaction costs matter: frequent rebalancing of many small positions can accumulate. Alpaca's commission-free trading helps, but bid-ask spreads still apply.

---

## Risk Management Framework

### Per-Trade Rules
| Rule | Penny Stocks | Commodity ETFs | Sector ETFs |
|------|-------------|----------------|-------------|
| Max risk per trade | 1.5-2% of equity | 3-5% of equity | 5% of equity |
| Stop-loss distance | 10-15% | 5% | 3-5% |
| Max position size | 3% of equity | 10% of equity | 20% of equity |
| Time stop (max hold) | Intraday - 5 days | 10-30 days | 30+ days |

### Portfolio-Level Rules
1. **Max total exposure to penny stocks:** 10% of portfolio
2. **Max total exposure to commodity ETFs:** 25% of portfolio
3. **Max correlation:** Do not hold 3+ positions in the same sector (e.g., 3 crypto miners)
4. **Daily loss limit:** If portfolio drops 3% in a single day, close all penny stock positions and halt new penny entries for 24 hours
5. **Weekly loss limit:** If portfolio drops 5% in a rolling 5-day window, reduce all positions by 50% and move to cash
6. **Max drawdown circuit breaker:** If portfolio drops 10% from its peak, close all positions and pause all strategies for 1 week. Review and revise before restarting.

### Position Sizing Formula
```
Position Size (shares) = (Portfolio Equity * Risk Per Trade %) / (Entry Price - Stop Price)
```

Example: $100,000 portfolio, 2% risk, entry at $2.50, stop at $2.25:
```
Shares = ($100,000 * 0.02) / ($2.50 - $2.25) = $2,000 / $0.25 = 8,000 shares
Dollar exposure = 8,000 * $2.50 = $20,000 (20% of portfolio -- check against max position size!)
```

If the calculated position exceeds the max position size, reduce to the max position size.

### Correlation Monitoring
Before entering a new position, check if it is correlated with existing holdings:
- Crypto mining stocks (BITF, ABTC, ARBK) are highly correlated with each other and with BTC. Treat them as one exposure bucket.
- GLD and SLV are correlated (0.7-0.85 typically). The ratio trade explicitly exploits the residual decorrelation.
- Energy ETFs (USO, UNG, XLE) share macro exposure to oil/gas prices.

---

## Implementation Notes

### Setting Up alpa_ex for Paper Trading

1. **Configuration** -- Set your Alpaca paper trading credentials:

```elixir
# In config/config.exs or config/dev.exs
config :alpa,
  api_key: System.get_env("ALPACA_API_KEY"),
  api_secret: System.get_env("ALPACA_API_SECRET"),
  paper: true  # Uses paper-api.alpaca.markets
```

2. **Environment variables:**
```bash
export ALPACA_API_KEY="your-paper-key"
export ALPACA_API_SECRET="your-paper-secret"
```

### Running Strategies

Each strategy module is designed to be called from an IEx session or scheduled via a GenServer/cron:

```elixir
# In IEx:
iex> Strategy.PennyMomentum.scan_and_trade()
iex> Strategy.CommodityMeanReversion.scan_mean_reversion()
iex> Strategy.BreakoutHunter.scan_breakouts()
iex> Strategy.GoldSilverRatio.analyze_and_rebalance()
iex> Strategy.MultiAssetMomentum.weekly_rebalance()
```

For automated scheduling, wrap in a GenServer with `Process.send_after/3`:

```elixir
defmodule Strategy.Scheduler do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_scan()
    {:ok, state}
  end

  def handle_info(:run_scans, state) do
    # Run during market hours only
    case Alpa.Trading.Market.clock() do
      {:ok, clock} when clock.is_open ->
        Strategy.PennyMomentum.scan_and_trade()
        Strategy.CommodityMeanReversion.scan_mean_reversion()
        Strategy.BreakoutHunter.scan_breakouts()
      _ ->
        IO.puts("Market closed. Skipping scans.")
    end

    schedule_scan()
    {:noreply, state}
  end

  defp schedule_scan do
    # Run every 15 minutes
    Process.send_after(self(), :run_scans, :timer.minutes(15))
  end
end
```

### Real-Time Streaming Alternative

For strategies that need tick-level data, use `Alpa.Stream.MarketData`:

```elixir
{:ok, stream} = Alpa.Stream.MarketData.start_link(
  callback: fn event ->
    case event.type do
      :trade -> handle_trade(event.data)
      :bar -> handle_bar(event.data)
      _ -> :ok
    end
  end,
  feed: "iex"
)

Alpa.Stream.MarketData.subscribe(stream,
  trades: ["BITF", "ABTC", "EVGO"],
  bars: ["GLD", "SLV", "USO"]
)
```

### Paper Trading Recommendations

1. **Run each strategy independently for at least 2 weeks** before combining them in a multi-strategy portfolio.
2. **Log every trade** with entry reason, expected outcome, and actual outcome. Review weekly.
3. **Alpaca allows 3 paper accounts** -- use separate accounts for penny stock strategies vs. commodity strategies vs. the multi-asset portfolio.
4. **Do not trust paper fills on penny stocks.** Paper trading fills at NBBO, but real penny stock fills often have 1-5% slippage. Mentally deduct 2% from every paper trade P&L for penny stocks.
5. **Check for PDT restrictions:** Paper accounts simulate Pattern Day Trader rules. If your account equity is below $25,000, you are limited to 3 day trades per 5 business days. The penny momentum strategy (with its same-day time stop) counts as day trades.

### Known Gotchas

- **Fractional shares:** Alpaca supports fractional shares for most stocks, but some penny stocks may not be eligible. Use whole share quantities to be safe.
- **Extended hours:** Penny stock strategies should avoid extended hours trading (wider spreads, lower liquidity). Set `extended_hours: false` on orders.
- **Rate limits:** Alpaca's API has rate limits (200 requests per minute for paper trading). If scanning a large watchlist, add small delays between API calls.
- **ETF-specific risks:** USO and UNG use futures contracts that roll monthly. Their long-term price behavior diverges significantly from the spot commodity price. These ETFs are better suited for short-term (days to weeks) trading, not buy-and-hold.
- **Bracket order behavior:** When one leg of a bracket order fills (take profit or stop loss), the other leg is automatically cancelled. You do not need to manually cancel the remaining leg.

---

## Sources

- [21 Best Penny Stocks for 2026 - XS](https://www.xs.com/en/blog/best-penny-stocks/)
- [10 Best Penny Stocks to Buy for 2026 - Insider Monkey](https://www.insidermonkey.com/blog/10-best-penny-stocks-to-buy-for-2026-1672696/)
- [4 Commodities ETFs to Invest in 2026 - The Motley Fool](https://www.fool.com/investing/how-to-invest/etfs/commodities-etfs/)
- [Commodity ETF List - ETF Database](https://etfdb.com/etfs/asset-class/commodity/)
- [Penny Stock Trading Strategies - TradersPost](https://blog.traderspost.io/article/penny-stock-trading-strategies)
- [Swing Trading ETFs Guide - VectorVest](https://www.vectorvest.com/blog/swing-trading/swing-trading-etfs/)
- [Momentum Strategies in Commodity Markets - The Hedge Fund Journal](https://thehedgefundjournal.com/momentum-strategies-in-commodity-markets/)
- [Alpaca Paper Trading Documentation](https://docs.alpaca.markets/docs/paper-trading)
- [How to Start Paper Trading with Alpaca](https://alpaca.markets/learn/start-paper-trading)
- [ETF Trading Strategies - QuantifiedStrategies.com](https://www.quantifiedstrategies.com/etf-trading-strategies/)
