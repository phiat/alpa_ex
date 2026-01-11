# Alpa

Elixir client library for the [Alpaca Trading API](https://alpaca.markets/).

Commission-free stock, options, and crypto trading with real-time market data.

## Features

- **Trading API** - Account management, orders, positions, watchlists
- **Market Data API** - Historical and real-time bars, quotes, trades, snapshots
- **WebSocket Streaming** - Real-time trade updates and market data
- **Options Trading** - Option contract search and trading
- **Crypto Trading** - 24/7 cryptocurrency trading
- **TypedStruct Models** - Fully typed responses with Decimal precision
- **Modern Stack** - Elixir 1.16+, Req HTTP client, WebSockex

## Installation

Add `alpa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:alpa, "~> 2.0"}
  ]
end
```

## Configuration

Set your API credentials as environment variables:

```bash
export APCA_API_KEY_ID="your-api-key"
export APCA_API_SECRET_KEY="your-api-secret"
export APCA_USE_PAPER="true"  # Use paper trading (default: true)
```

Or configure in your application:

```elixir
# config/runtime.exs
config :alpa,
  api_key: System.get_env("APCA_API_KEY_ID"),
  api_secret: System.get_env("APCA_API_SECRET_KEY"),
  use_paper: true
```

## Quick Start

```elixir
# Get account info
{:ok, account} = Alpa.account()
IO.puts("Buying power: $#{account.buying_power}")

# Check if market is open
{:ok, open?} = Alpa.market_open?()

# Place a market order
{:ok, order} = Alpa.buy("AAPL", 10)

# Get positions
{:ok, positions} = Alpa.positions()

# Get market data
{:ok, bars} = Alpa.bars("AAPL", timeframe: "1Day", limit: 30)

# Get a market snapshot
{:ok, snapshot} = Alpa.snapshot("AAPL")
IO.puts("AAPL last trade: $#{snapshot.latest_trade.price}")
```

## Trading

### Orders

```elixir
# Market orders
{:ok, order} = Alpa.buy("AAPL", 10)
{:ok, order} = Alpa.sell("AAPL", 10)

# Limit order
{:ok, order} = Alpa.place_order(
  symbol: "AAPL",
  qty: 10,
  side: "buy",
  type: "limit",
  limit_price: "150.00",
  time_in_force: "gtc"
)

# Bracket order (entry with take-profit and stop-loss)
{:ok, order} = Alpa.place_order(
  symbol: "AAPL",
  qty: 10,
  side: "buy",
  type: "market",
  time_in_force: "day",
  order_class: "bracket",
  take_profit: %{limit_price: "160.00"},
  stop_loss: %{stop_price: "140.00", limit_price: "139.00"}
)

# List orders
{:ok, orders} = Alpa.orders(status: "open")

# Cancel orders
{:ok, _} = Alpa.cancel_order(order_id)
{:ok, _} = Alpa.cancel_all_orders()
```

### Positions

```elixir
# List all positions
{:ok, positions} = Alpa.positions()

# Get specific position
{:ok, position} = Alpa.position("AAPL")

# Close positions
{:ok, order} = Alpa.close_position("AAPL")
{:ok, order} = Alpa.close_position("AAPL", percentage: 50)  # Close 50%
{:ok, _} = Alpa.close_all_positions()
```

### Account

```elixir
# Account info
{:ok, account} = Alpa.account()

# Portfolio history
{:ok, history} = Alpa.history(period: "1M", timeframe: "1D")

# Account configuration
{:ok, config} = Alpa.account_config()
```

## Market Data

### Historical Data

```elixir
# Bars (OHLCV)
{:ok, bars} = Alpa.bars("AAPL",
  timeframe: "1Day",
  start: ~U[2024-01-01 00:00:00Z],
  limit: 100
)

# Quotes
{:ok, quotes} = Alpa.quotes("AAPL",
  start: ~U[2024-01-15 14:30:00Z],
  limit: 100
)

# Trades
{:ok, trades} = Alpa.trades("AAPL",
  start: ~U[2024-01-15 14:30:00Z],
  limit: 100
)

# Multi-symbol
{:ok, bars} = Alpa.MarketData.Bars.get_multi(
  ["AAPL", "MSFT", "GOOGL"],
  timeframe: "1Day"
)
```

### Latest Data

```elixir
# Latest bar, quote, trade
{:ok, bar} = Alpa.latest_bar("AAPL")
{:ok, quote} = Alpa.latest_quote("AAPL")
{:ok, trade} = Alpa.latest_trade("AAPL")

# Snapshot (all latest data combined)
{:ok, snapshot} = Alpa.snapshot("AAPL")
# => %Alpa.Models.Snapshot{
#      latest_trade: %Alpa.Models.Trade{...},
#      latest_quote: %Alpa.Models.Quote{...},
#      minute_bar: %Alpa.Models.Bar{...},
#      daily_bar: %Alpa.Models.Bar{...},
#      prev_daily_bar: %Alpa.Models.Bar{...}
#    }

# Multiple snapshots
{:ok, snapshots} = Alpa.snapshots(["AAPL", "MSFT", "GOOGL"])
```

## Real-Time Streaming

### Trade Updates (Order Status)

```elixir
# Stream order fills, cancellations, etc.
{:ok, pid} = Alpa.Stream.TradeUpdates.start_link(
  callback: fn event ->
    IO.puts("#{event.event}: #{event.order.symbol} @ #{event.price}")
  end
)

# Events: new, fill, partial_fill, canceled, expired, replaced, rejected
```

### Market Data Streaming

```elixir
# Start the stream
{:ok, pid} = Alpa.Stream.MarketData.start_link(
  callback: fn event ->
    case event.type do
      :trade -> IO.puts("Trade: #{event.data.symbol} @ #{event.data.price}")
      :quote -> IO.puts("Quote: #{event.data.symbol} bid=#{event.data.bid_price}")
      :bar -> IO.puts("Bar: #{event.data.symbol} close=#{event.data.close}")
    end
  end,
  feed: "iex"  # or "sip" for all exchanges
)

# Subscribe to symbols
Alpa.Stream.MarketData.subscribe(pid,
  trades: ["AAPL", "MSFT"],
  quotes: ["AAPL"],
  bars: ["SPY"]
)

# Unsubscribe
Alpa.Stream.MarketData.unsubscribe(pid, trades: ["MSFT"])

# Stop
Alpa.Stream.MarketData.stop(pid)
```

## Options Trading

```elixir
# Search for option contracts
{:ok, result} = Alpa.Options.Contracts.search("AAPL",
  type: :call,
  expiration_date_gte: ~D[2024-03-01],
  strike_price_gte: "150",
  strike_price_lte: "200"
)

# Get specific contract
{:ok, contract} = Alpa.Options.Contracts.get("AAPL240315C00175000")

# Trade options using regular order functions
{:ok, order} = Alpa.place_order(
  symbol: "AAPL240315C00175000",
  qty: 1,
  side: "buy",
  type: "limit",
  limit_price: "5.00",
  time_in_force: "day"
)
```

## Crypto Trading

```elixir
# List crypto assets
{:ok, assets} = Alpa.Crypto.Trading.assets()

# Buy/sell crypto
{:ok, order} = Alpa.Crypto.Trading.buy("BTC/USD", "0.001")
{:ok, order} = Alpa.Crypto.Trading.sell("ETH/USD", "0.1")

# Buy by dollar amount
{:ok, order} = Alpa.Crypto.Trading.buy_notional("BTC/USD", "100")  # $100 of BTC

# Crypto positions
{:ok, positions} = Alpa.Crypto.Trading.positions()
```

## Modules

| Module | Description |
|--------|-------------|
| `Alpa` | Main facade with delegated functions |
| `Alpa.Trading.Account` | Account info, config, activities, portfolio history |
| `Alpa.Trading.Orders` | Order placement and management |
| `Alpa.Trading.Positions` | Position management |
| `Alpa.Trading.Assets` | Asset information |
| `Alpa.Trading.Watchlists` | Watchlist CRUD |
| `Alpa.Trading.Market` | Market clock and calendar |
| `Alpa.MarketData.Bars` | Historical bar data |
| `Alpa.MarketData.Quotes` | Historical quote data |
| `Alpa.MarketData.Trades` | Historical trade data |
| `Alpa.MarketData.Snapshots` | Market snapshots |
| `Alpa.Stream.TradeUpdates` | Real-time trade updates |
| `Alpa.Stream.MarketData` | Real-time market data |
| `Alpa.Options.Contracts` | Options contract search |
| `Alpa.Crypto.Trading` | Crypto trading operations |

## Error Handling

All API functions return `{:ok, result}` or `{:error, %Alpa.Error{}}`:

```elixir
case Alpa.account() do
  {:ok, account} ->
    IO.puts("Balance: $#{account.cash}")

  {:error, %Alpa.Error{type: :unauthorized}} ->
    IO.puts("Check your API credentials")

  {:error, %Alpa.Error{type: :rate_limited}} ->
    IO.puts("Rate limited, try again later")

  {:error, error} ->
    IO.puts("Error: #{error}")
end
```

Error types: `:unauthorized`, `:forbidden`, `:not_found`, `:unprocessable_entity`, `:rate_limited`, `:server_error`, `:network_error`, `:timeout`

## Configuration Options

| Option | Environment Variable | Default |
|--------|---------------------|---------|
| `api_key` | `APCA_API_KEY_ID` | - |
| `api_secret` | `APCA_API_SECRET_KEY` | - |
| `use_paper` | `APCA_USE_PAPER` | `true` |
| `timeout` | - | `30_000` |
| `receive_timeout` | - | `30_000` |

Options can be passed to any function to override config:

```elixir
Alpa.account(api_key: "other-key", api_secret: "other-secret")
```

## Development

```bash
# Run tests
mix test

# Run tests with coverage
mix coveralls

# Generate docs
mix docs

# Run static analysis
mix credo
mix dialyzer
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Alpaca API Documentation](https://docs.alpaca.markets/)
- [Hex Package](https://hex.pm/packages/alpa)
- [GitHub Repository](https://github.com/phiat/alpa_ex)
