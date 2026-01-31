# Architecture

## Module Structure

```
lib/
├── alpa.ex                        # Main facade (delegates to submodules)
├── alpa/
│   ├── application.ex             # OTP Application
│   ├── client.ex                  # HTTP client (Req-based) + telemetry
│   ├── config.ex                  # Configuration management
│   ├── error.ex                   # Error types and handling
│   ├── pagination.ex              # Pagination helpers (all/2, stream/2)
│   ├── trading/
│   │   ├── account.ex             # Account, config, activities, history
│   │   ├── orders.ex              # Order CRUD + helpers
│   │   ├── positions.ex           # Position management + exercise
│   │   ├── assets.ex              # Asset lookup
│   │   ├── watchlists.ex          # Watchlist CRUD
│   │   ├── market.ex              # Clock, calendar
│   │   └── corporate_actions.ex   # Announcements
│   ├── market_data/
│   │   ├── bars.ex                # OHLCV bars
│   │   ├── quotes.ex              # NBBO quotes
│   │   ├── trades.ex              # Trade data
│   │   └── snapshots.ex           # Market snapshots
│   ├── stream/
│   │   ├── trade_updates.ex       # WebSocket: order events
│   │   └── market_data.ex         # WebSocket: market feed
│   ├── options/
│   │   └── contracts.ex           # Option contract search
│   ├── crypto/
│   │   ├── funding.ex             # Crypto wallets and transfers
│   │   ├── trading.ex             # Crypto-specific trading helpers
│   │   ├── market_data.ex         # Crypto bars, quotes, trades, snapshots, orderbook
│   │   └── funding.ex             # Crypto transfers and wallets
│   └── models/
│       ├── account.ex             # Account struct
│       ├── account_config.ex      # Account configuration struct
│       ├── activity.ex            # Activity struct (with Decimal)
│       ├── asset.ex               # Asset struct
│       ├── bar.ex                 # OHLCV bar struct
│       ├── calendar.ex            # Market calendar day struct
│       ├── clock.ex               # Market clock struct
│       ├── corporate_action.ex    # Corporate action struct
│       ├── crypto_transfer.ex     # Crypto transfer struct
│       ├── crypto_wallet.ex       # Crypto wallet struct
│       ├── option_contract.ex     # Option contract struct
│       ├── order.ex               # Order struct
│       ├── portfolio_history.ex   # Portfolio history struct
│       ├── position.ex            # Position struct
│       ├── quote.ex               # Quote struct
│       ├── snapshot.ex            # Snapshot struct
│       ├── trade.ex               # Trade struct
│       └── watchlist.ex           # Watchlist struct
```

## Design Principles

1. **Facade pattern** — `Alpa` module delegates to specific modules for convenience
2. **TypedStruct models** — All API responses are parsed into typed structs with Decimal precision
3. **Config cascade** — Function opts > env vars > app config > defaults
4. **Consistent error handling** — All functions return `{:ok, result} | {:error, %Alpa.Error{}}`
5. **Paper-first** — Defaults to paper trading for safety

## HTTP Client

`Alpa.Client` wraps `Req` with:
- Auth headers (`APCA-API-KEY-ID`, `APCA-API-SECRET-KEY`)
- Automatic JSON encode/decode
- Transient retry with exponential backoff
- Configurable timeouts

## Telemetry

All API calls emit telemetry events via `:telemetry`:

| Event | Measurements | Metadata |
|-------|-------------|----------|
| `[:alpa, :request, :start]` | `%{system_time: integer}` | `%{method, path, url}` |
| `[:alpa, :request, :stop]` | `%{duration: integer}` | `%{method, path, url}` |
| `[:alpa, :request, :exception]` | `%{duration: integer}` | `%{method, path, url, error}` |

Attach handlers to monitor latency, error rates, or log requests:

```elixir
:telemetry.attach("alpa-logger", [:alpa, :request, :stop], fn _event, measurements, metadata, _config ->
  Logger.info("#{metadata.method} #{metadata.path} took #{measurements.duration}ns")
end, nil)
```

## Pagination

`Alpa.Pagination` provides helpers for paginated endpoints:

```elixir
# Eagerly fetch all pages
{:ok, all_orders} = Alpa.Pagination.all(&Alpa.Trading.Orders.list/1, limit: 100)

# Lazy stream
Alpa.Pagination.stream(&Alpa.Trading.Orders.list/1, limit: 50)
|> Stream.take(200)
|> Enum.to_list()
```

## WebSocket Streaming

`Alpa.Stream.TradeUpdates` and `Alpa.Stream.MarketData` use WebSockex for:
- Authenticated WebSocket connections
- Auto-subscribe after auth
- Callback-based event handling (function or MFA tuple)
- Exponential backoff reconnection with jitter (1s to 60s max)
- Connection state tracking (`:connecting`, `:connected`, `:disconnected`)

## See Also

- [Getting Started](Getting-Started.md) -- Installation and quick start
- [API Coverage](API-Coverage.md) -- Full endpoint coverage matrix
- [Trading Strategies](Trading-Strategies.md) -- Example strategies and patterns
- [Contributing](Contributing.md) -- Development setup and guidelines
