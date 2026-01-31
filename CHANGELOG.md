# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-10

### Added

- Complete rewrite with modern Elixir 1.16+ stack
- **HTTP Client**: Switched from HTTPoison to Req for better performance and DX
- **TypedStruct Models**: All API responses now use typed structs with Decimal precision
- **Runtime Configuration**: Proper runtime config via `config/runtime.exs`
- **Structured Errors**: `Alpa.Error` struct with typed error categories

#### Trading API
- Account information and configuration
- Full order management (place, replace, cancel) with all order types
- Bracket orders, OCO, OTO support
- Position management with partial close support
- Asset queries with filtering
- Watchlist CRUD operations
- Market clock and calendar

#### Market Data API (v2)
- Historical bars with timeframe and adjustment options
- Historical quotes (NBBO data)
- Historical trades
- Market snapshots (combined latest data)
- Multi-symbol queries for all data types
- Latest bar/quote/trade endpoints

#### WebSocket Streaming
- `Alpa.Stream.TradeUpdates` - Real-time order status updates
- `Alpa.Stream.MarketData` - Real-time trades, quotes, and bars
- Automatic reconnection handling
- Subscription management

#### Options Trading
- Option contract search with filtering
- Contract lookup by symbol or ID

#### Crypto Trading
- Crypto asset queries
- Crypto position management
- Buy/sell with quantity or notional amount

#### Crypto Funding
- Wallet listing
- Transfer listing and lookup
- Withdrawal requests

### Changed

- Minimum Elixir version: 1.16 (was 1.10)
- API responses now return typed structs instead of raw maps
- Configuration uses runtime.exs instead of compile-time config
- Error handling uses structured `Alpa.Error` type

### Removed

- Legacy v1 bars endpoint (now uses v2 market data API)
- Compile-time configuration via `Application.get_env`

## [0.1.6] - 2020-03

- Added orders list and update
- Added account config

## [0.1.5] - 2020-03

- Added calendar and clock
- Handle 422 errors

## [0.1.4] - 2020-03

- Added portfolio history

## [0.1.3] - 2020-03

- Added positions and watchlists

## [0.1.2] - 2020-03

- Added market data (bars)
- Multiple endpoint support

## [0.1.1] - 2020-03

- Hex docs

## [0.1.0] - 2020-03

- Initial release
- Basic account info, buy, sell, delete orders
