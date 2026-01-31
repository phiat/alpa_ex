# API Coverage

## Alpaca Trading API v2

| Endpoint | Method | Path | Module | Status |
|----------|--------|------|--------|--------|
| **Account** | | | | |
| Get Account | GET | `/v2/account` | `Alpa.Trading.Account` | Done |
| Get Config | GET | `/v2/account/configurations` | `Alpa.Trading.Account` | Done (typed) |
| Update Config | PATCH | `/v2/account/configurations` | `Alpa.Trading.Account` | Done |
| Get Activities | GET | `/v2/account/activities` | `Alpa.Trading.Account` | Done (typed) |
| Get Activities by Type | GET | `/v2/account/activities/{type}` | `Alpa.Trading.Account` | Done (typed) |
| Portfolio History | GET | `/v2/account/portfolio/history` | `Alpa.Trading.Account` | Done (typed) |
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
| Clock | GET | `/v2/clock` | `Alpa.Trading.Market` | Done (typed) |
| Calendar | GET | `/v2/calendar` | `Alpa.Trading.Market` | Done (typed) |
| **Corporate Actions** | | | | |
| List Announcements | GET | `/v2/corporate_actions/announcements` | `Alpa.Trading.CorporateActions` | Done |
| Get Announcement | GET | `/v2/corporate_actions/announcements/{id}` | `Alpa.Trading.CorporateActions` | Done |
| **Market Data (Stocks)** | | | | |
| Bars/Quotes/Trades | GET | `/v2/stocks/*` | `Alpa.MarketData.*` | Done |
| Snapshots | GET | `/v2/stocks/snapshots` | `Alpa.MarketData.Snapshots` | Done |
| **Crypto Market Data** | | | | |
| Crypto Bars | GET | `/v1beta3/crypto/{loc}/bars` | `Alpa.Crypto.MarketData` | Done |
| Crypto Quotes | GET | `/v1beta3/crypto/{loc}/quotes` | `Alpa.Crypto.MarketData` | Done |
| Crypto Trades | GET | `/v1beta3/crypto/{loc}/trades` | `Alpa.Crypto.MarketData` | Done |
| Crypto Snapshots | GET | `/v1beta3/crypto/{loc}/snapshots` | `Alpa.Crypto.MarketData` | Done |
| Crypto Orderbook | GET | `/v1beta3/crypto/{loc}/orderbooks` | `Alpa.Crypto.MarketData` | Done |
| **Crypto Funding** | | | | |
| List Wallets | GET | `/v2/crypto/funding/wallets` | `Alpa.Crypto.Funding` | Done |
| List Transfers | GET | `/v2/crypto/funding/transfers` | `Alpa.Crypto.Funding` | Done |
| Get Transfer | GET | `/v2/crypto/funding/transfers/{id}` | `Alpa.Crypto.Funding` | Done |
| Create Transfer | POST | `/v2/crypto/funding/transfers` | `Alpa.Crypto.Funding` | Done |
| **Streaming** | | | | |
| Trade Updates | WSS | `/stream` | `Alpa.Stream.TradeUpdates` | Done |
| Market Data | WSS | `/v2/{feed}` | `Alpa.Stream.MarketData` | Done |
| **Crypto Trading** | | | | |
| Crypto Trading | Various | `/v2/orders` | `Alpa.Crypto.Trading` | Done |

## Cross-Cutting Features

| Feature | Module | Status |
|---------|--------|--------|
| Telemetry events (`[:alpa, :request, :start\|:stop\|:exception]`) | `Alpa.Client` | Done |
| Pagination helpers (`all/2`, `stream/2`) | `Alpa.Pagination` | Done |
| Typed models (AccountConfig, Activity, PortfolioHistory, Calendar) | `Alpa.Models.*` | Done |
| Exponential backoff reconnection with jitter | `Alpa.Stream.*` | Done |
