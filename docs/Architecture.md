# Architecture

## Module Structure

```
lib/
├── alpa.ex                        # Main facade (delegates to submodules)
├── alpa/
│   ├── application.ex             # OTP Application
│   ├── client.ex                  # HTTP client (Req-based)
│   ├── config.ex                  # Configuration management
│   ├── error.ex                   # Error types and handling
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
│   │   └── trading.ex             # Crypto-specific helpers
│   └── models/
│       ├── account.ex             # Account struct
│       ├── asset.ex               # Asset struct
│       ├── bar.ex                 # OHLCV bar struct
│       ├── clock.ex               # Market clock struct
│       ├── option_contract.ex     # Option contract struct
│       ├── order.ex               # Order struct
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

## WebSocket Streaming

`Alpa.Stream.TradeUpdates` and `Alpa.Stream.MarketData` use WebSockex for:
- Authenticated WebSocket connections
- Auto-subscribe after auth
- Callback-based event handling (function or MFA tuple)
- Automatic reconnection on disconnect
