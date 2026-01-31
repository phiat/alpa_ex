# Getting Started

## Prerequisites

- Elixir 1.16+
- An Alpaca Markets account ([sign up free](https://alpaca.markets/))
- API keys from the Alpaca dashboard

## Installation

Add `alpa_ex` to your `mix.exs`:

```elixir
def deps do
  [{:alpa_ex, "~> 1.0"}]
end
```

Then run:

```bash
mix deps.get
```

## Configuration

### Environment Variables (recommended)

```bash
export APCA_API_KEY_ID="your-key"
export APCA_API_SECRET_KEY="your-secret"
export APCA_USE_PAPER="true"  # defaults to true for safety
```

### Application Config

```elixir
# config/runtime.exs
config :alpa_ex,
  api_key: System.get_env("APCA_API_KEY_ID"),
  api_secret: System.get_env("APCA_API_SECRET_KEY"),
  use_paper: true
```

### Per-Call Override

```elixir
Alpa.account(api_key: "other-key", api_secret: "other-secret")
```

## Quick Start

```elixir
# Get account info
{:ok, account} = Alpa.account()
IO.puts("Buying power: $#{account.buying_power}")

# Check market status
{:ok, open?} = Alpa.market_open?()

# Place a market order
{:ok, order} = Alpa.buy("AAPL", 10)

# Get positions
{:ok, positions} = Alpa.positions()

# Get market data
{:ok, bars} = Alpa.bars("AAPL", timeframe: "1Day", limit: 30)

# Get a snapshot
{:ok, snapshot} = Alpa.snapshot("AAPL")
```

## Crypto Trading

```elixir
# Buy crypto
{:ok, order} = Alpa.Crypto.Trading.buy("BTC/USD", notional: "100.00")

# Get crypto market data
{:ok, bars} = Alpa.Crypto.MarketData.get_bars("BTC/USD", timeframe: "1Hour")
{:ok, snapshot} = Alpa.Crypto.MarketData.get_snapshots(["BTC/USD", "ETH/USD"])
```

## Pagination

For endpoints that return paginated results:

```elixir
# Fetch all orders across pages
{:ok, all_orders} = Alpa.Pagination.all(&Alpa.Trading.Orders.list/1, limit: 100)

# Or use lazy streaming
Alpa.Pagination.stream(&Alpa.Trading.Orders.list/1, limit: 50)
|> Stream.filter(fn order -> order.status == "filled" end)
|> Enum.to_list()
```

## Telemetry

Monitor API calls with telemetry:

```elixir
:telemetry.attach("alpa-logger", [:alpa, :request, :stop], fn _event, measurements, metadata, _config ->
  Logger.info("#{metadata.method} #{metadata.path} took #{div(measurements.duration, 1_000_000)}ms")
end, nil)
```

## Error Handling

All functions return `{:ok, result}` or `{:error, %Alpa.Error{}}`:

```elixir
case Alpa.account() do
  {:ok, account} -> IO.puts("Balance: $#{account.cash}")
  {:error, %Alpa.Error{type: :unauthorized}} -> IO.puts("Check credentials")
  {:error, %Alpa.Error{type: :rate_limited}} -> IO.puts("Rate limited")
  {:error, error} -> IO.puts("Error: #{error}")
end
```

## WebSocket Streaming

```elixir
# Stream trade updates
{:ok, pid} = Alpa.Stream.TradeUpdates.start_link(
  callback: fn event -> IO.inspect(event, label: "trade_update") end
)

# Stream market data
{:ok, pid} = Alpa.Stream.MarketData.start_link(
  feed: :iex,
  trades: ["AAPL", "TSLA"],
  callback: fn event -> IO.inspect(event) end
)
```
