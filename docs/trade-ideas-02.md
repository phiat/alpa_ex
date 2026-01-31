# Trading Ideas: Penny Stocks, Commodities, and Cross-Asset Strategies

> **Document ID:** TRADE-IDEAS-02
> **Date:** January 2026
> **SDK:** alpa_ex (Elixir client for Alpaca Markets API)
> **Status:** Research / Paper Trading
> **Risk Disclaimer:** All strategies described herein are for educational and research purposes. Past performance does not guarantee future results. Trade only with capital you can afford to lose.

---

## Table of Contents

1. [Platform Considerations](#platform-considerations)
2. [Strategy 1: Low-Price Equity Momentum Scanner](#strategy-1-low-price-equity-momentum-scanner)
3. [Strategy 2: Commodity ETF Rotation](#strategy-2-commodity-etf-rotation)
4. [Strategy 3: Small-Cap Value Screener](#strategy-3-small-cap-value-screener)
5. [Strategy 4: Crypto-Commodity Correlation](#strategy-4-crypto-commodity-correlation)
6. [Strategy 5: Earnings Season Small-Cap Catalyst](#strategy-5-earnings-season-small-cap-catalyst)
7. [Portfolio Allocation Framework](#portfolio-allocation-framework)

---

## Platform Considerations

### Alpaca Markets Asset Coverage

Alpaca supports US-listed equities, ETFs, options, and 20+ cryptocurrency pairs. The platform provides commission-free trading, fractional shares, and extended-hours access (4:00 AM - 8:00 PM ET).

**Critical constraint:** Alpaca does not support traditional penny stocks (OTC/Pink Sheets). All strategies referencing "low-price" or "small-cap" equities in this document target exchange-listed securities on NYSE, NASDAQ, and AMEX that trade below $10. This is a deliberate design choice -- exchange-listed low-price stocks offer better liquidity, stricter reporting requirements, and reduced fraud risk compared to OTC markets.

### Environment Setup

```bash
export APCA_API_KEY_ID="your-key"
export APCA_API_SECRET_KEY="your-secret"
export APCA_USE_PAPER="true"
```

### Shared Utility Module

All strategies depend on the following helper module for risk sizing and common operations:

```elixir
defmodule Strategy.Util do
  @moduledoc "Shared utilities for all trading strategies."

  @doc "Calculate position size as a percentage of portfolio equity."
  def position_size_dollars(account, pct) do
    account.equity
    |> Decimal.mult(Decimal.from_float(pct))
    |> Decimal.round(2)
  end

  @doc "Calculate quantity from dollar amount and price."
  def qty_from_notional(dollars, price) do
    Decimal.div(dollars, price)
    |> Decimal.round(0, :floor)
    |> Decimal.to_integer()
  end

  @doc "Simple moving average over a list of Decimal close prices."
  def sma(bars, period) do
    bars
    |> Enum.take(-period)
    |> Enum.map(& &1.close)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    |> Decimal.div(Decimal.new(period))
  end

  @doc "Relative Strength Index calculation."
  def rsi(bars, period \\ 14) do
    changes =
      bars
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [prev, curr] -> Decimal.sub(curr.close, prev.close) end)
      |> Enum.take(-period)

    gains = changes |> Enum.filter(&(Decimal.compare(&1, Decimal.new(0)) == :gt))
    losses = changes |> Enum.filter(&(Decimal.compare(&1, Decimal.new(0)) == :lt))

    avg_gain = safe_avg(gains, period)
    avg_loss = safe_avg(Enum.map(losses, &Decimal.abs/1), period)

    case Decimal.compare(avg_loss, Decimal.new(0)) do
      :eq -> Decimal.new(100)
      _ ->
        rs = Decimal.div(avg_gain, avg_loss)
        Decimal.sub(Decimal.new(100), Decimal.div(Decimal.new(100), Decimal.add(Decimal.new(1), rs)))
    end
  end

  defp safe_avg([], _period), do: Decimal.new(0)
  defp safe_avg(values, period) do
    Enum.reduce(values, Decimal.new(0), &Decimal.add/2)
    |> Decimal.div(Decimal.new(period))
  end

  @doc "Compute percentage return between two Decimal prices."
  def pct_return(entry, current) do
    Decimal.sub(current, entry)
    |> Decimal.div(entry)
    |> Decimal.mult(Decimal.new(100))
    |> Decimal.round(2)
  end
end
```

---

## Strategy 1: Low-Price Equity Momentum Scanner

### Overview

| Field | Detail |
|---|---|
| **Type** | Momentum / Breakout |
| **Instruments** | Exchange-listed equities trading between $1.00 and $10.00 |
| **Holding Period** | 1-5 trading days |
| **Risk Level** | HIGH |

### Market Thesis

Exchange-listed stocks in the $1-$10 range exhibit outsized intraday moves when catalyzed by volume surges, earnings surprises, or sector momentum. In 2026, thematic momentum in AI, clean energy, biotech, and defense has created recurring setups where low-price equities gap up on news and sustain multi-day runs. The strategy scans for unusual volume relative to a 20-day average and confirms breakouts above resistance before entering.

The approach avoids OTC/Pink Sheet securities entirely, relying on the higher reporting standards of NASDAQ and NYSE-listed names.

### Target Instruments

Focus on equities with the following characteristics:
- Listed on NYSE, NASDAQ, or AMEX (enforced by Alpaca's universe)
- Price between $1.00 and $10.00
- Average daily volume above 500,000 shares
- Positive revenue trajectory or identifiable catalyst

Sectors of interest in Q1 2026: AI infrastructure, battery/EV supply chain, defense subcontractors, biotech with upcoming FDA milestones.

### Entry Criteria

1. Current price is between $1.00 and $10.00
2. Today's volume exceeds 2x the 20-day average volume
3. Price is above the 10-day SMA (confirming uptrend)
4. RSI(14) is between 50 and 75 (momentum without exhaustion)

### Exit Criteria

- **Take profit:** +15% from entry
- **Stop loss:** -7% from entry
- **Time stop:** Close position after 5 trading days if neither target is hit

### Risk Management

- Maximum 3% of portfolio per position
- Maximum 3 concurrent low-price equity positions (9% total exposure)
- No position in stocks with market cap below $50M
- Halt new entries if 3 consecutive losses occur (reassess thesis)

### Implementation

```elixir
defmodule Strategy.LowPriceMomentum do
  @moduledoc """
  Scans exchange-listed equities ($1-$10) for momentum breakouts
  confirmed by unusual volume and trend alignment.
  """

  alias Strategy.Util

  @min_price Decimal.new("1.00")
  @max_price Decimal.new("10.00")
  @volume_multiplier 2.0
  @rsi_low Decimal.new("50")
  @rsi_high Decimal.new("75")
  @take_profit_pct Decimal.new("0.15")
  @stop_loss_pct Decimal.new("-0.07")
  @max_position_pct 0.03

  @doc "Run the full scan and return candidate symbols."
  def scan do
    {:ok, assets} = Alpa.assets(status: "active", asset_class: "us_equity")

    tradeable =
      assets
      |> Enum.filter(& &1.tradable)
      |> Enum.filter(&(&1.exchange in ["NASDAQ", "NYSE", "AMEX", "ARCA"]))

    symbols = Enum.map(tradeable, & &1.symbol)

    # Process in batches of 50 to respect API rate limits
    symbols
    |> Enum.chunk_every(50)
    |> Enum.flat_map(&scan_batch/1)
  end

  defp scan_batch(symbols) do
    {:ok, snapshots} = Alpa.MarketData.Snapshots.get_multi(symbols)

    snapshots
    |> Enum.filter(fn {_sym, snap} ->
      price = snap.daily_bar.close
      in_range?(price) and volume_surge?(snap)
    end)
    |> Enum.map(fn {sym, _snap} -> sym end)
    |> Enum.flat_map(&evaluate_candidate/1)
  end

  defp evaluate_candidate(symbol) do
    with {:ok, bars} <- Alpa.bars(symbol,
           timeframe: "1Day",
           limit: 25,
           start: ago_days(30)) do
      sma_10 = Util.sma(bars, 10)
      rsi_14 = Util.rsi(bars, 14)
      current = List.last(bars).close

      cond do
        Decimal.compare(current, sma_10) != :gt -> []
        Decimal.compare(rsi_14, @rsi_low) == :lt -> []
        Decimal.compare(rsi_14, @rsi_high) == :gt -> []
        true -> [%{symbol: symbol, price: current, rsi: rsi_14, sma_10: sma_10}]
      end
    else
      _ -> []
    end
  end

  @doc "Enter a position for a scanned candidate."
  def enter(candidate) do
    {:ok, account} = Alpa.account()
    dollars = Util.position_size_dollars(account, @max_position_pct)
    qty = Util.qty_from_notional(dollars, candidate.price)

    if qty > 0 do
      take_profit =
        candidate.price
        |> Decimal.mult(Decimal.add(Decimal.new(1), @take_profit_pct))
        |> Decimal.round(2)

      stop_loss =
        candidate.price
        |> Decimal.mult(Decimal.add(Decimal.new(1), @stop_loss_pct))
        |> Decimal.round(2)

      Alpa.place_order(
        symbol: candidate.symbol,
        qty: to_string(qty),
        side: "buy",
        type: "market",
        time_in_force: "day",
        order_class: "bracket",
        take_profit: %{limit_price: Decimal.to_string(take_profit)},
        stop_loss: %{stop_price: Decimal.to_string(stop_loss)}
      )
    else
      {:error, :insufficient_funds}
    end
  end

  # Helpers

  defp in_range?(price) do
    Decimal.compare(price, @min_price) != :lt and
      Decimal.compare(price, @max_price) != :gt
  end

  defp volume_surge?(snapshot) do
    daily_vol = snapshot.daily_bar.volume || 0
    prev_vol = snapshot.prev_daily_bar.volume || 1
    daily_vol > prev_vol * @volume_multiplier
  end

  defp ago_days(n) do
    DateTime.utc_now()
    |> DateTime.add(-n * 86_400, :second)
  end
end

# Usage:
# candidates = Strategy.LowPriceMomentum.scan()
# Enum.each(Enum.take(candidates, 3), &Strategy.LowPriceMomentum.enter/1)
```

---

## Strategy 2: Commodity ETF Rotation

### Overview

| Field | Detail |
|---|---|
| **Type** | Relative Strength Rotation |
| **Instruments** | GLD, SLV, IAU, SIVR, USO, UNG, WEAT, DBA, PDBC, CPER |
| **Holding Period** | 2-8 weeks (rebalance biweekly) |
| **Risk Level** | MODERATE |

### Market Thesis

Commodity markets in early 2026 are characterized by a powerful precious metals rally -- gold near $4,460/oz and silver having surged 269% year-over-year -- while energy commodities have lagged. The gold-to-silver ratio compressed from 104:1 to 64:1, signaling silver strength. Goldman Sachs targets $4,900/oz gold by year-end 2026, and Bank of America forecasts $5,000/oz.

This rotation strategy ranks commodity ETFs by recent momentum (20-day and 60-day returns), allocates capital to the top performers, and rotates out of laggards on a biweekly schedule. It captures trending commodity cycles while avoiding concentration in a single metal or energy product.

Key risk: SLV has shown blow-off top characteristics with record ETF volume ($14.3B in a single session). The strategy incorporates mean-reversion filters to avoid entering parabolic moves.

### Target Instruments

| Ticker | Commodity | Expense Ratio |
|---|---|---|
| GLD | Gold (physical) | 0.40% |
| IAU | Gold (physical) | 0.25% |
| SLV | Silver (physical) | 0.50% |
| SIVR | Silver (physical) | 0.30% |
| USO | Crude Oil (futures) | 0.60% |
| UNG | Natural Gas (futures) | 1.06% |
| WEAT | Wheat (futures) | 0.28% |
| DBA | Agriculture basket | 0.85% |
| PDBC | Diversified commodity | 0.59% |
| CPER | Copper (futures) | 0.65% |

### Entry Criteria

1. Rank all ETFs by a composite score: 0.6 * (20-day return) + 0.4 * (60-day return)
2. Select top 3 ETFs by composite score
3. Exclude any ETF where price is >50% above its 200-day SMA (blow-off filter)
4. Equal-weight allocate across selected ETFs

### Exit Criteria

- **Rotation exit:** ETF drops out of top 3 ranking at next biweekly rebalance
- **Emergency stop:** Any ETF drops >10% from entry in a single week
- **Blow-off exit:** ETF exceeds 60% above its 200-day SMA mid-cycle

### Risk Management

- Maximum 20% of portfolio allocated to this strategy
- Equal-weight across 3 positions (~6.7% each)
- No leverage on commodity ETFs
- Cash reserve: if fewer than 2 ETFs pass filters, hold remainder in cash

### Implementation

```elixir
defmodule Strategy.CommodityRotation do
  @moduledoc """
  Rotates between commodity ETFs based on relative strength
  with a blow-off filter for overextended assets.
  """

  alias Strategy.Util

  @etfs ~w(GLD IAU SLV SIVR USO UNG WEAT DBA PDBC CPER)
  @top_n 3
  @max_strategy_pct 0.20
  @blowoff_threshold Decimal.new("1.50")

  @doc "Rank commodity ETFs and return top N candidates."
  def rank do
    sixty_days_ago = DateTime.add(DateTime.utc_now(), -60 * 86_400, :second)

    rankings =
      @etfs
      |> Enum.map(fn etf ->
        with {:ok, bars} <- Alpa.bars(etf,
               timeframe: "1Day",
               start: sixty_days_ago,
               limit: 65) do
          compute_ranking(etf, bars)
        else
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(& &1.blowoff)
      |> Enum.sort_by(& &1.composite, {:desc, Decimal})
      |> Enum.take(@top_n)

    rankings
  end

  defp compute_ranking(etf, bars) when length(bars) >= 20 do
    current = List.last(bars).close
    bar_20 = Enum.at(bars, -21)
    bar_60 = List.first(bars)

    ret_20 = pct_change(bar_20.close, current)
    ret_60 = pct_change(bar_60.close, current)

    composite =
      Decimal.add(
        Decimal.mult(ret_20, Decimal.from_float(0.6)),
        Decimal.mult(ret_60, Decimal.from_float(0.4))
      )

    sma_200 = if length(bars) >= 60, do: Util.sma(bars, 60), else: current
    ratio = Decimal.div(current, sma_200)
    blowoff = Decimal.compare(ratio, @blowoff_threshold) != :lt

    %{
      symbol: etf,
      ret_20: ret_20,
      ret_60: ret_60,
      composite: composite,
      price: current,
      blowoff: blowoff
    }
  end

  defp compute_ranking(_etf, _bars), do: nil

  @doc "Execute the rotation: sell holdings not in top N, buy new top N."
  def rebalance do
    top = rank()
    top_symbols = MapSet.new(Enum.map(top, & &1.symbol))

    {:ok, account} = Alpa.account()
    {:ok, positions} = Alpa.positions()

    strategy_dollars = Util.position_size_dollars(account, @max_strategy_pct)
    per_position = Decimal.div(strategy_dollars, Decimal.new(@top_n))

    # Close positions not in the current top N
    positions
    |> Enum.filter(&(&1.symbol in @etfs))
    |> Enum.reject(&MapSet.member?(top_symbols, &1.symbol))
    |> Enum.each(fn pos ->
      Alpa.close_position(pos.symbol)
    end)

    # Open or adjust positions for top N
    held_symbols =
      positions
      |> Enum.filter(&(&1.symbol in @etfs))
      |> Enum.map(& &1.symbol)
      |> MapSet.new()

    top
    |> Enum.reject(&MapSet.member?(held_symbols, &1.symbol))
    |> Enum.each(fn candidate ->
      qty = Util.qty_from_notional(per_position, candidate.price)
      if qty > 0 do
        Alpa.buy(candidate.symbol, to_string(qty))
      end
    end)
  end

  defp pct_change(old, new) do
    Decimal.sub(new, old) |> Decimal.div(old) |> Decimal.mult(Decimal.new(100))
  end
end

# Usage (run biweekly):
# Strategy.CommodityRotation.rank()    # preview rankings
# Strategy.CommodityRotation.rebalance()  # execute trades
```

---

## Strategy 3: Small-Cap Value Screener

### Overview

| Field | Detail |
|---|---|
| **Type** | Value / Mean Reversion |
| **Instruments** | Exchange-listed equities, market cap $300M - $2B |
| **Holding Period** | 4-12 weeks |
| **Risk Level** | MODERATE-HIGH |

### Market Thesis

Small-cap stocks have traded at their widest valuation discount to large-caps since 1999. The Russell 2000 opened 2026 with a 5.73% gain, and Bank of America forecasts 17% small-cap earnings growth versus 14% for large-caps. Rate cuts and broadening earnings growth create favorable conditions for a multi-quarter rotation into quality small-caps.

The strategy uses a price-based mean reversion screen combined with fundamental quality proxies available through Alpaca's market data: sustained trading activity, positive multi-month price trend with a recent pullback, and recovery confirmation above short-term moving averages.

Because Alpaca does not provide fundamental data (P/E, revenue, etc.) directly, the strategy uses price and volume as proxy signals and relies on a curated watchlist of fundamentally vetted small-cap names sourced from external screeners.

### Target Instruments

Curated watchlist of fundamentally screened small-caps (examples from Q1 2026 screens):

| Ticker | Name | Sector | Rationale |
|---|---|---|---|
| EVER | EverQuote | Technology | Strong revenue growth, value score |
| ORN | Orion Group Holdings | Industrials | Infrastructure spending beneficiary |
| SMP | Standard Motor Products | Consumer Discretionary | Demand visibility |
| GRR | Asia Tigers Fund | International | Deep discount to NAV |
| IJR | iShares Core S&P Small-Cap | ETF | Broad quality small-cap exposure |
| IWM | iShares Russell 2000 | ETF | Broad small-cap index exposure |

### Entry Criteria

1. Price has pulled back 10-20% from its 60-day high (mean reversion setup)
2. Price has recovered above the 10-day SMA (momentum confirmation)
3. 20-day average volume exceeds 200,000 shares (liquidity filter)
4. RSI(14) between 35 and 55 (oversold recovery zone)

### Exit Criteria

- **Take profit:** +20% from entry, or price reaches the previous 60-day high
- **Stop loss:** -10% from entry
- **Time stop:** 12 weeks maximum hold

### Risk Management

- Maximum 5% of portfolio per position
- Maximum 5 positions (25% total allocation to this strategy)
- Diversify across at least 3 sectors
- If IWM drops below its 200-day SMA, reduce all positions by 50%

### Implementation

```elixir
defmodule Strategy.SmallCapValue do
  @moduledoc """
  Screens small-cap equities for mean reversion entries
  after pullbacks in fundamentally sound names.
  """

  alias Strategy.Util

  # Curated watchlist -- update quarterly based on external fundamental screens
  @watchlist ~w(EVER ORN SMP VSTS GRNT CARG PTGX)

  @pullback_min Decimal.new("0.10")
  @pullback_max Decimal.new("0.20")
  @rsi_low Decimal.new("35")
  @rsi_high Decimal.new("55")
  @take_profit Decimal.new("0.20")
  @stop_loss Decimal.new("-0.10")
  @max_position_pct 0.05

  @doc "Screen the watchlist for mean reversion candidates."
  def screen do
    sixty_days_ago = DateTime.add(DateTime.utc_now(), -60 * 86_400, :second)

    @watchlist
    |> Enum.map(fn symbol ->
      with {:ok, bars} <- Alpa.bars(symbol,
             timeframe: "1Day",
             start: sixty_days_ago,
             limit: 65),
           true <- length(bars) >= 20 do
        evaluate(symbol, bars)
      else
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp evaluate(symbol, bars) do
    current = List.last(bars).close
    high_60 = bars |> Enum.map(& &1.close) |> Enum.max_by(&Decimal.to_float/1)
    drawdown = Decimal.sub(high_60, current) |> Decimal.div(high_60)

    sma_10 = Util.sma(bars, 10)
    rsi_14 = Util.rsi(bars, 14)

    pullback_ok =
      Decimal.compare(drawdown, @pullback_min) != :lt and
      Decimal.compare(drawdown, @pullback_max) != :gt

    above_sma = Decimal.compare(current, sma_10) != :lt

    rsi_ok =
      Decimal.compare(rsi_14, @rsi_low) != :lt and
      Decimal.compare(rsi_14, @rsi_high) != :gt

    avg_volume =
      bars
      |> Enum.take(-20)
      |> Enum.map(& &1.volume)
      |> then(fn vols -> Enum.sum(vols) / length(vols) end)

    if pullback_ok and above_sma and rsi_ok and avg_volume > 200_000 do
      %{
        symbol: symbol,
        price: current,
        high_60: high_60,
        drawdown: Decimal.round(drawdown, 4),
        rsi: Decimal.round(rsi_14, 1),
        avg_volume: round(avg_volume)
      }
    else
      nil
    end
  end

  @doc "Enter a mean reversion position with bracket order."
  def enter(candidate) do
    {:ok, account} = Alpa.account()
    dollars = Util.position_size_dollars(account, @max_position_pct)
    qty = Util.qty_from_notional(dollars, candidate.price)

    take_price =
      candidate.price
      |> Decimal.mult(Decimal.add(Decimal.new(1), @take_profit))
      |> Decimal.round(2)

    # Cap take profit at the previous 60-day high
    take_price =
      case Decimal.compare(take_price, candidate.high_60) do
        :gt -> candidate.high_60
        _ -> take_price
      end

    stop_price =
      candidate.price
      |> Decimal.mult(Decimal.add(Decimal.new(1), @stop_loss))
      |> Decimal.round(2)

    if qty > 0 do
      Alpa.place_order(
        symbol: candidate.symbol,
        qty: to_string(qty),
        side: "buy",
        type: "market",
        time_in_force: "day",
        order_class: "bracket",
        take_profit: %{limit_price: Decimal.to_string(take_price)},
        stop_loss: %{stop_price: Decimal.to_string(stop_price)}
      )
    else
      {:error, :insufficient_funds}
    end
  end

  @doc "Check IWM regime and reduce exposure if below 200-day SMA."
  def regime_check do
    {:ok, bars} = Alpa.bars("IWM", timeframe: "1Day", limit: 210,
      start: DateTime.add(DateTime.utc_now(), -220 * 86_400, :second))

    if length(bars) >= 200 do
      sma_200 = Util.sma(bars, 200)
      current = List.last(bars).close

      if Decimal.compare(current, sma_200) == :lt do
        :reduce_exposure
      else
        :full_exposure
      end
    else
      :insufficient_data
    end
  end
end

# Usage:
# candidates = Strategy.SmallCapValue.screen()
# regime = Strategy.SmallCapValue.regime_check()
# if regime == :full_exposure do
#   Enum.each(Enum.take(candidates, 5), &Strategy.SmallCapValue.enter/1)
# end
```

---

## Strategy 4: Crypto-Commodity Correlation

### Overview

| Field | Detail |
|---|---|
| **Type** | Pairs / Correlation Trading |
| **Instruments** | BTC/USD, ETH/USD + GLD, SLV, QQQ |
| **Holding Period** | 1-4 weeks |
| **Risk Level** | HIGH |

### Market Thesis

Bitcoin ($92,698) and gold ($4,460/oz) have both rallied in early 2026, but analysts note the correlation is coincidental rather than structural. Gold responds to geopolitical risk and central bank demand; Bitcoin trades with risk-asset sensitivity and institutional ETF flows. The BTC/gold ratio has historically mean-reverted after reaching Z-score extremes: a Z-score below -2 preceded 150% BTC rallies in previous cycles.

The strategy exploits three correlation pairs:

1. **BTC vs. Gold (GLD):** When the BTC/GLD ratio reaches a Z-score extreme, trade the expected mean reversion. Long BTC + short GLD on Z < -2; reverse on Z > +2.
2. **ETH vs. QQQ:** ETH correlates with technology risk appetite. Divergences between ETH/USD daily returns and QQQ returns create short-term reversion opportunities.
3. **BTC vs. SLV:** Silver's parabolic move in 2026 has decoupled from its historical relationship with Bitcoin. Monitor for SLV exhaustion as a signal to rotate into BTC.

### Entry Criteria

**Pair 1 -- BTC/Gold Z-Score:**
1. Compute the 60-day rolling BTC/GLD price ratio
2. Compute Z-score of the current ratio relative to the 60-day mean and standard deviation
3. Enter long BTC (via `Alpa.Crypto.Trading`) and short GLD when Z < -1.5
4. Enter long GLD and reduce BTC when Z > +1.5

**Pair 2 -- ETH/QQQ Divergence:**
1. Compute 5-day cumulative return for ETH/USD and QQQ
2. If ETH underperforms QQQ by >8% over 5 days, buy ETH (anticipate catch-up)
3. If ETH outperforms QQQ by >8% over 5 days, sell ETH (anticipate reversion)

### Exit Criteria

- **Mean reversion target:** Z-score returns to the range [-0.5, +0.5]
- **Stop loss:** Z-score moves 1.0 further against the position (i.e., entry at -1.5, stop at -2.5)
- **Time stop:** 4 weeks maximum

### Risk Management

- Maximum 10% of portfolio in crypto positions
- Maximum 10% in the GLD/SLV hedge leg
- Never hold naked short crypto (Alpaca does not support this for crypto)
- Use notional orders for precise dollar-amount allocation on crypto

### Implementation

```elixir
defmodule Strategy.CryptoCommodity do
  @moduledoc """
  Trades mean-reverting relationships between crypto assets
  and commodity ETFs using Z-score analysis.
  """

  alias Strategy.Util

  @z_entry_threshold Decimal.new("-1.5")
  @z_exit_low Decimal.new("-0.5")
  @z_exit_high Decimal.new("0.5")
  @max_crypto_pct 0.10
  @max_etf_pct 0.10

  @doc "Compute the BTC/GLD ratio Z-score over the trailing 60 days."
  def btc_gold_zscore do
    sixty_days_ago = DateTime.add(DateTime.utc_now(), -60 * 86_400, :second)

    with {:ok, btc_bars} <- Alpa.crypto_bars("BTC/USD",
           timeframe: "1Day",
           start: sixty_days_ago,
           limit: 65),
         {:ok, gld_bars} <- Alpa.bars("GLD",
           timeframe: "1Day",
           start: sixty_days_ago,
           limit: 65) do
      # Align bars by date
      btc_by_date = index_by_date(btc_bars)
      gld_by_date = index_by_date(gld_bars)

      common_dates =
        MapSet.intersection(
          MapSet.new(Map.keys(btc_by_date)),
          MapSet.new(Map.keys(gld_by_date))
        )
        |> MapSet.to_list()
        |> Enum.sort()

      ratios =
        Enum.map(common_dates, fn date ->
          Decimal.div(btc_by_date[date].close, gld_by_date[date].close)
        end)

      if length(ratios) >= 20 do
        mean = avg(ratios)
        std_dev = std(ratios, mean)
        current_ratio = List.last(ratios)

        z_score =
          if Decimal.compare(std_dev, Decimal.new(0)) == :gt do
            Decimal.div(Decimal.sub(current_ratio, mean), std_dev)
          else
            Decimal.new(0)
          end

        %{
          z_score: Decimal.round(z_score, 2),
          current_ratio: Decimal.round(current_ratio, 2),
          mean_ratio: Decimal.round(mean, 2),
          std_dev: Decimal.round(std_dev, 2),
          signal: classify_signal(z_score)
        }
      else
        {:error, :insufficient_data}
      end
    end
  end

  @doc "Compute ETH vs QQQ 5-day return divergence."
  def eth_qqq_divergence do
    five_days_ago = DateTime.add(DateTime.utc_now(), -7 * 86_400, :second)

    with {:ok, eth_bars} <- Alpa.crypto_bars("ETH/USD",
           timeframe: "1Day", start: five_days_ago, limit: 7),
         {:ok, qqq_bars} <- Alpa.bars("QQQ",
           timeframe: "1Day", start: five_days_ago, limit: 7) do
      eth_ret = period_return(eth_bars)
      qqq_ret = period_return(qqq_bars)
      divergence = Decimal.sub(eth_ret, qqq_ret)

      %{
        eth_return: Decimal.round(eth_ret, 2),
        qqq_return: Decimal.round(qqq_ret, 2),
        divergence: Decimal.round(divergence, 2),
        signal: cond do
          Decimal.compare(divergence, Decimal.new("-8")) == :lt -> :buy_eth
          Decimal.compare(divergence, Decimal.new("8")) == :gt -> :sell_eth
          true -> :neutral
        end
      }
    end
  end

  @doc "Execute BTC/Gold pair trade based on Z-score signal."
  def execute_btc_gold(signal_data) do
    {:ok, account} = Alpa.account()

    case signal_data.signal do
      :long_btc_short_gld ->
        crypto_dollars = Util.position_size_dollars(account, @max_crypto_pct)
        etf_dollars = Util.position_size_dollars(account, @max_etf_pct)

        # Buy BTC via notional order
        Alpa.Crypto.Trading.buy_notional("BTC/USD", Decimal.to_string(crypto_dollars))

        # Buy inverse or sell GLD (using available shares)
        {:ok, gld_quote} = Alpa.latest_quote("GLD")
        gld_price = gld_quote.ask_price || gld_quote.bid_price
        gld_qty = Util.qty_from_notional(etf_dollars, gld_price)

        if gld_qty > 0 do
          Alpa.sell("GLD", to_string(gld_qty))
        end

      :neutral ->
        :no_action

      _ ->
        :no_action
    end
  end

  @doc "Execute ETH/QQQ divergence trade."
  def execute_eth_qqq(divergence_data) do
    {:ok, account} = Alpa.account()
    dollars = Util.position_size_dollars(account, @max_crypto_pct)

    case divergence_data.signal do
      :buy_eth ->
        Alpa.Crypto.Trading.buy_notional("ETH/USD", Decimal.to_string(dollars))
      :sell_eth ->
        Alpa.Crypto.Trading.sell_notional("ETH/USD", Decimal.to_string(dollars))
      :neutral ->
        :no_action
    end
  end

  # Private helpers

  defp classify_signal(z) do
    cond do
      Decimal.compare(z, @z_entry_threshold) != :gt -> :long_btc_short_gld
      Decimal.compare(z, Decimal.negate(@z_entry_threshold)) != :lt -> :long_gld_short_btc
      true -> :neutral
    end
  end

  defp index_by_date(bars) do
    Map.new(bars, fn bar ->
      date = DateTime.to_date(bar.timestamp)
      {date, bar}
    end)
  end

  defp period_return(bars) when length(bars) >= 2 do
    first = List.first(bars).close
    last = List.last(bars).close
    Decimal.sub(last, first) |> Decimal.div(first) |> Decimal.mult(Decimal.new(100))
  end

  defp period_return(_), do: Decimal.new(0)

  defp avg(values) do
    sum = Enum.reduce(values, Decimal.new(0), &Decimal.add/2)
    Decimal.div(sum, Decimal.new(length(values)))
  end

  defp std(values, mean) do
    variance =
      values
      |> Enum.map(fn v ->
        diff = Decimal.sub(v, mean)
        Decimal.mult(diff, diff)
      end)
      |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
      |> Decimal.div(Decimal.new(length(values)))

    # Approximate square root via Newton's method
    sqrt_decimal(variance)
  end

  defp sqrt_decimal(n) do
    n_float = Decimal.to_float(n)
    Decimal.from_float(:math.sqrt(max(n_float, 0.0)))
  end
end

# Usage:
# signal = Strategy.CryptoCommodity.btc_gold_zscore()
# IO.inspect(signal, label: "BTC/Gold Signal")
# Strategy.CryptoCommodity.execute_btc_gold(signal)
#
# div_signal = Strategy.CryptoCommodity.eth_qqq_divergence()
# IO.inspect(div_signal, label: "ETH/QQQ Divergence")
# Strategy.CryptoCommodity.execute_eth_qqq(div_signal)
```

---

## Strategy 5: Earnings Season Small-Cap Catalyst

### Overview

| Field | Detail |
|---|---|
| **Type** | Event-Driven / Catalyst |
| **Instruments** | Exchange-listed small-caps ($2-$20) with upcoming earnings |
| **Holding Period** | 1-10 trading days (event window) |
| **Risk Level** | HIGH |

### Market Thesis

Earnings announcements in small-cap stocks produce outsized moves because of thinner analyst coverage and lower institutional ownership. A stock with 2 analysts covering it will move far more on a surprise than one with 30. In 2026, with small-cap earnings growth expected at 17% (Bank of America), the probability of upside surprises is elevated.

The strategy enters positions 1-3 days before earnings in names showing pre-earnings accumulation (rising volume, positive price drift), and uses strict defined risk via bracket orders. The asymmetry is favorable: small-caps that beat earnings in a growth environment often gap 10-30%, while defined-risk orders cap downside at a fixed percentage.

Because Alpaca does not provide an earnings calendar API, this strategy integrates with a curated list of upcoming earnings dates maintained externally.

### Target Instruments

Maintained as a rotating watchlist updated weekly during earnings season. Selection criteria:

- Exchange-listed on NYSE or NASDAQ
- Price between $2 and $20
- Average daily volume > 300,000 shares
- Earnings date within the next 5 trading days
- At least 1 analyst estimate available (to define a consensus to beat)

### Entry Criteria

1. Earnings date is 1-3 trading days away
2. Volume over the past 3 days exceeds the 20-day average by 1.5x (accumulation signal)
3. Price is within 5% of or above the 20-day SMA (not in freefall)
4. No existing position in the same sector (diversification)

### Exit Criteria

- **Post-earnings take profit:** +20% from entry (let winners run through day 1 post-earnings)
- **Post-earnings stop loss:** -8% from entry (triggered pre-market if gap down occurs)
- **Time stop:** Close 5 trading days after earnings regardless of outcome
- **Pre-earnings bailout:** If price drops >5% before earnings, exit before the event

### Risk Management

- Maximum 2% of portfolio per position (high-risk event trades)
- Maximum 4 concurrent earnings positions (8% total)
- Never hold more than 1 position in the same sector
- Reduce position sizes by 50% if win rate drops below 40% over the last 10 trades

### Implementation

```elixir
defmodule Strategy.EarningsCatalyst do
  @moduledoc """
  Trades small-cap stocks around earnings announcements,
  entering on pre-earnings accumulation signals with defined risk.
  """

  alias Strategy.Util

  @max_position_pct 0.02
  @take_profit_pct Decimal.new("0.20")
  @stop_loss_pct Decimal.new("-0.08")
  @pre_earnings_bail Decimal.new("-0.05")
  @volume_threshold 1.5

  @doc """
  Evaluate a list of upcoming earnings candidates.
  Each candidate is a map with :symbol and :earnings_date keys.
  """
  def evaluate(candidates) when is_list(candidates) do
    candidates
    |> Enum.map(&evaluate_single/1)
    |> Enum.reject(&is_nil/1)
  end

  defp evaluate_single(%{symbol: symbol, earnings_date: _date}) do
    twenty_days_ago = DateTime.add(DateTime.utc_now(), -25 * 86_400, :second)

    with {:ok, bars} <- Alpa.bars(symbol,
           timeframe: "1Day",
           start: twenty_days_ago,
           limit: 25),
         true <- length(bars) >= 20 do
      current = List.last(bars).close
      sma_20 = Util.sma(bars, 20)

      # Volume accumulation check
      recent_3d_vol =
        bars |> Enum.take(-3) |> Enum.map(& &1.volume) |> Enum.sum() |> div(3)

      avg_20d_vol =
        bars |> Enum.take(-20) |> Enum.map(& &1.volume) |> Enum.sum() |> div(20)

      vol_ratio = if avg_20d_vol > 0, do: recent_3d_vol / avg_20d_vol, else: 0

      # Price near or above SMA
      price_to_sma =
        Decimal.sub(current, sma_20)
        |> Decimal.div(sma_20)
        |> Decimal.to_float()

      if vol_ratio >= @volume_threshold and price_to_sma >= -0.05 do
        %{
          symbol: symbol,
          price: current,
          sma_20: sma_20,
          vol_ratio: Float.round(vol_ratio, 2),
          price_to_sma_pct: Float.round(price_to_sma * 100, 1),
          avg_volume: avg_20d_vol
        }
      else
        nil
      end
    else
      _ -> nil
    end
  end

  @doc "Enter a pre-earnings position with bracket order."
  def enter(candidate) do
    {:ok, account} = Alpa.account()
    dollars = Util.position_size_dollars(account, @max_position_pct)
    qty = Util.qty_from_notional(dollars, candidate.price)

    take_price =
      candidate.price
      |> Decimal.mult(Decimal.add(Decimal.new(1), @take_profit_pct))
      |> Decimal.round(2)

    stop_price =
      candidate.price
      |> Decimal.mult(Decimal.add(Decimal.new(1), @stop_loss_pct))
      |> Decimal.round(2)

    if qty > 0 do
      Alpa.place_order(
        symbol: candidate.symbol,
        qty: to_string(qty),
        side: "buy",
        type: "market",
        time_in_force: "day",
        order_class: "bracket",
        take_profit: %{limit_price: Decimal.to_string(take_price)},
        stop_loss: %{stop_price: Decimal.to_string(stop_price)}
      )
    else
      {:error, :insufficient_funds}
    end
  end

  @doc "Monitor open earnings positions and enforce the pre-earnings bailout."
  def monitor_positions do
    {:ok, positions} = Alpa.positions()

    positions
    |> Enum.each(fn pos ->
      ret = Util.pct_return(pos.avg_entry_price, pos.current_price)

      if Decimal.compare(ret, Decimal.mult(@pre_earnings_bail, Decimal.new(100))) == :lt do
        IO.puts("BAIL: #{pos.symbol} at #{Decimal.to_string(ret)}% -- closing before earnings")
        Alpa.close_position(pos.symbol)
      end
    end)
  end

  @doc "Close all earnings positions past the time stop window."
  def cleanup_expired(max_age_days \\ 5) do
    {:ok, positions} = Alpa.positions()
    {:ok, orders} = Alpa.orders(status: "filled", limit: 100)

    now = DateTime.utc_now()

    positions
    |> Enum.each(fn pos ->
      entry_order =
        Enum.find(orders, fn o ->
          o.symbol == pos.symbol and o.side == :buy and o.status == :filled
        end)

      if entry_order do
        days_held =
          DateTime.diff(now, entry_order.filled_at, :second) / 86_400

        if days_held >= max_age_days do
          IO.puts("TIME STOP: #{pos.symbol} held #{Float.round(days_held, 1)} days -- closing")
          Alpa.close_position(pos.symbol)
        end
      end
    end)
  end
end

# Usage:
# upcoming = [
#   %{symbol: "EVER", earnings_date: ~D[2026-02-05]},
#   %{symbol: "ORN",  earnings_date: ~D[2026-02-06]},
#   %{symbol: "SMP",  earnings_date: ~D[2026-02-07]}
# ]
#
# candidates = Strategy.EarningsCatalyst.evaluate(upcoming)
# Enum.each(Enum.take(candidates, 4), &Strategy.EarningsCatalyst.enter/1)
#
# # Daily monitoring:
# Strategy.EarningsCatalyst.monitor_positions()
# Strategy.EarningsCatalyst.cleanup_expired()
```

---

## Portfolio Allocation Framework

### Recommended Allocation Across Strategies

| Strategy | Max Allocation | Max Positions | Risk Level |
|---|---|---|---|
| Low-Price Momentum | 9% | 3 | HIGH |
| Commodity ETF Rotation | 20% | 3 | MODERATE |
| Small-Cap Value | 25% | 5 | MODERATE-HIGH |
| Crypto-Commodity Correlation | 20% | 4 | HIGH |
| Earnings Season Catalyst | 8% | 4 | HIGH |
| **Cash Reserve** | **18%** | -- | -- |
| **Total** | **100%** | **19** | -- |

### Portfolio-Level Risk Controls

```elixir
defmodule Strategy.PortfolioGuard do
  @moduledoc """
  Portfolio-level risk management overlay. Run daily before
  any strategy execution to enforce aggregate constraints.
  """

  @max_drawdown_pct Decimal.new("-15.0")

  @doc "Check if portfolio drawdown exceeds maximum threshold."
  def drawdown_check do
    {:ok, account} = Alpa.account()

    current = account.equity
    peak = account.last_equity  # previous close equity

    drawdown =
      Decimal.sub(current, peak)
      |> Decimal.div(peak)
      |> Decimal.mult(Decimal.new(100))

    if Decimal.compare(drawdown, @max_drawdown_pct) == :lt do
      IO.puts("PORTFOLIO HALT: Drawdown #{Decimal.to_string(drawdown)}% exceeds limit")
      :halt_all_strategies
    else
      :continue
    end
  end

  @doc "Report current portfolio exposure by strategy."
  def exposure_report do
    {:ok, positions} = Alpa.positions()
    {:ok, account} = Alpa.account()

    total_value =
      positions
      |> Enum.map(& &1.market_value)
      |> Enum.reduce(Decimal.new(0), fn val, acc ->
        if val, do: Decimal.add(acc, Decimal.abs(val)), else: acc
      end)

    exposure_pct =
      if Decimal.compare(account.equity, Decimal.new(0)) == :gt do
        Decimal.div(total_value, account.equity)
        |> Decimal.mult(Decimal.new(100))
        |> Decimal.round(1)
      else
        Decimal.new(0)
      end

    %{
      total_positions: length(positions),
      total_market_value: total_value,
      equity: account.equity,
      exposure_pct: exposure_pct,
      cash: account.cash,
      buying_power: account.buying_power,
      daytrade_count: account.daytrade_count
    }
  end
end

# Usage (run at start of each trading day):
# case Strategy.PortfolioGuard.drawdown_check() do
#   :halt_all_strategies -> IO.puts("All strategies paused")
#   :continue -> IO.inspect(Strategy.PortfolioGuard.exposure_report())
# end
```

### Daily Operations Checklist

1. Run `Strategy.PortfolioGuard.drawdown_check()` -- halt if breached
2. Run `Strategy.PortfolioGuard.exposure_report()` -- verify within limits
3. Run `Strategy.EarningsCatalyst.monitor_positions()` -- enforce pre-earnings bailouts
4. Run `Strategy.EarningsCatalyst.cleanup_expired()` -- close time-stopped positions
5. Execute individual strategy scans and trades in order of priority
6. Log all trades and signals to external persistence layer

---

## Appendix: Key API Reference

| Function | Module | Purpose |
|---|---|---|
| `Alpa.account/0` | `Alpa.Trading.Account` | Account equity, buying power, day-trade count |
| `Alpa.positions/0` | `Alpa.Trading.Positions` | All open positions |
| `Alpa.assets/1` | `Alpa.Trading.Assets` | Filter tradeable assets by class, exchange |
| `Alpa.buy/3` | `Alpa.Trading.Orders` | Market buy order |
| `Alpa.sell/3` | `Alpa.Trading.Orders` | Market sell order |
| `Alpa.place_order/1` | `Alpa.Trading.Orders` | Full order with bracket, OCO, stop-loss |
| `Alpa.close_position/1` | `Alpa.Trading.Positions` | Close a specific position |
| `Alpa.bars/2` | `Alpa.MarketData.Bars` | Historical OHLCV bars |
| `Alpa.latest_quote/2` | `Alpa.MarketData.Quotes` | Latest NBBO quote |
| `Alpa.snapshot/2` | `Alpa.MarketData.Snapshots` | Full snapshot (trade, quote, bars) |
| `Alpa.snapshots/2` | `Alpa.MarketData.Snapshots` | Multi-symbol snapshots |
| `Alpa.crypto_bars/2` | `Alpa.Crypto.MarketData` | Crypto historical bars |
| `Alpa.Crypto.Trading.buy_notional/3` | `Alpa.Crypto.Trading` | Buy crypto by dollar amount |
| `Alpa.Crypto.Trading.sell_notional/3` | `Alpa.Crypto.Trading` | Sell crypto by dollar amount |

---

*Document prepared January 2026. All market data, prices, and analyst forecasts cited reflect conditions as of the preparation date and should be independently verified before trading.*
