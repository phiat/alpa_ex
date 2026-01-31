# API Coverage

## Alpaca Trading API v2

| Endpoint | Method | Path | Module | Status |
|----------|--------|------|--------|--------|
| **Account** | | | | |
| Get Account | GET | `/v2/account` | `Alpa.Trading.Account` | Done |
| Get Config | GET | `/v2/account/configurations` | `Alpa.Trading.Account` | Done |
| Update Config | PATCH | `/v2/account/configurations` | `Alpa.Trading.Account` | Done |
| Get Activities | GET | `/v2/account/activities` | `Alpa.Trading.Account` | Done |
| Get Activities by Type | GET | `/v2/account/activities/{type}` | `Alpa.Trading.Account` | Done |
| Portfolio History | GET | `/v2/account/portfolio/history` | `Alpa.Trading.Account` | Done |
| **Orders** | | | | |
| Create Order | POST | `/v2/orders` | `Alpa.Trading.Orders` | Done |
| List Orders | GET | `/v2/orders` | `Alpa.Trading.Orders` | Done |
| Get Order | GET | `/v2/orders/{id}` | `Alpa.Trading.Orders` | Done |
| Get by Client ID | GET | `/v2/orders:by_client_order_id` | `Alpa.Trading.Orders` | Done |
| Replace Order | PATCH | `/v2/orders/{id}` | `Alpa.Trading.Orders` | Done |
| Cancel Order | DELETE | `/v2/orders/{id}` | `Alpa.Trading.Orders` | Done |
| Cancel All | DELETE | `/v2/orders` | `Alpa.Trading.Orders` | Done |
| **Positions** | | | | |
| List Positions | GET | `/v2/positions` | `Alpa.Trading.Positions` | Done |
| Get Position | GET | `/v2/positions/{symbol}` | `Alpa.Trading.Positions` | Done |
| Close Position | DELETE | `/v2/positions/{symbol}` | `Alpa.Trading.Positions` | Done |
| Close All | DELETE | `/v2/positions` | `Alpa.Trading.Positions` | Done |
| Exercise Option | POST | `/v2/positions/{symbol}/exercise` | `Alpa.Trading.Positions` | Done |
| **Assets** | | | | |
| List Assets | GET | `/v2/assets` | `Alpa.Trading.Assets` | Done |
| Get Asset | GET | `/v2/assets/{symbol}` | `Alpa.Trading.Assets` | Done |
| Option Contracts | GET | `/v2/option-contracts` | `Alpa.Options.Contracts` | Done |
| **Watchlists** | | | | |
| Full CRUD | Various | `/v2/watchlists/*` | `Alpa.Trading.Watchlists` | Done |
| **Market** | | | | |
| Clock | GET | `/v2/clock` | `Alpa.Trading.Market` | Done |
| Calendar | GET | `/v2/calendar` | `Alpa.Trading.Market` | Done |
| **Corporate Actions** | | | | |
| List Announcements | GET | `/v2/corporate_actions/announcements` | `Alpa.Trading.CorporateActions` | Done |
| Get Announcement | GET | `/v2/corporate_actions/announcements/{id}` | `Alpa.Trading.CorporateActions` | Done |
| **Market Data** | | | | |
| Bars/Quotes/Trades | GET | `/v2/stocks/*` | `Alpa.MarketData.*` | Done |
| Snapshots | GET | `/v2/stocks/snapshots` | `Alpa.MarketData.Snapshots` | Done |
| **Streaming** | | | | |
| Trade Updates | WSS | `/stream` | `Alpa.Stream.TradeUpdates` | Done |
| Market Data | WSS | `/v2/{feed}` | `Alpa.Stream.MarketData` | Done |
| **Crypto** | | | | |
| Crypto Trading | Various | `/v2/orders` | `Alpa.Crypto.Trading` | Done |

## Planned

- Typed models for activities, portfolio history, calendar (#13)
- Pagination helpers (#16)
- Telemetry instrumentation (#17)
- Crypto market data endpoints (#18)
- WebSocket reconnection improvements (#19)
