defmodule Alpa do
  @moduledoc """
  Elixir client library for the Alpaca Trading API.

  ## Quick Start

  Set your API credentials as environment variables:

      export APCA_API_KEY_ID="your-key"
      export APCA_API_SECRET_KEY="your-secret"
      export APCA_USE_PAPER="true"  # optional, defaults to true

  Then use the API:

      # Get account info
      {:ok, account} = Alpa.account()

      # Place a market order
      {:ok, order} = Alpa.buy("AAPL", 10)

      # Get positions
      {:ok, positions} = Alpa.positions()

      # Get market data
      {:ok, bars} = Alpa.bars("AAPL", timeframe: "1Day")

      # Get a market snapshot
      {:ok, snapshot} = Alpa.snapshot("AAPL")

  ## Modules

  For more advanced usage, use the specific modules:

    * `Alpa.Trading.Account` - Account information and configuration
    * `Alpa.Trading.Orders` - Order placement and management
    * `Alpa.Trading.Positions` - Position management
    * `Alpa.Trading.Assets` - Asset information
    * `Alpa.Trading.Watchlists` - Watchlist management
    * `Alpa.Trading.Market` - Market clock and calendar
    * `Alpa.MarketData.Bars` - Historical bar data
    * `Alpa.MarketData.Quotes` - Quote (NBBO) data
    * `Alpa.MarketData.Trades` - Trade data
    * `Alpa.MarketData.Snapshots` - Market snapshots
    * `Alpa.Crypto.Trading` - Crypto trading (orders, positions, assets)
    * `Alpa.Crypto.MarketData` - Crypto market data (bars, quotes, trades, snapshots)
    * `Alpa.Crypto.Funding` - Crypto wallets and transfers
    * `Alpa.Options.Contracts` - Options contract search and lookup

  ## Configuration

  Configuration can be set via:

  1. Environment variables (recommended for credentials)
  2. Application config
  3. Options passed directly to functions

  See `Alpa.Config` for details.
  """

  alias Alpa.Crypto.Funding
  alias Alpa.Crypto.MarketData, as: CryptoMarketData
  alias Alpa.Crypto.Trading, as: CryptoTrading
  alias Alpa.MarketData.{Bars, Quotes, Snapshots, Trades}
  alias Alpa.Options.Contracts, as: OptionsContracts
  alias Alpa.Trading.{Account, Assets, CorporateActions, Market, Orders, Positions, Watchlists}

  # ============================================================================
  # Account
  # ============================================================================

  @doc """
  Get account information.

  See `Alpa.Trading.Account.get/1` for details.
  """
  defdelegate account(opts \\ []), to: Account, as: :get

  @doc """
  Get account configurations.

  See `Alpa.Trading.Account.get_configurations/1` for details.
  """
  defdelegate account_config(opts \\ []), to: Account, as: :get_configurations

  @doc """
  Get portfolio history.

  See `Alpa.Trading.Account.get_portfolio_history/1` for details.
  """
  defdelegate history(opts \\ []), to: Account, as: :get_portfolio_history

  # ============================================================================
  # Orders
  # ============================================================================

  @doc """
  Place a new order.

  See `Alpa.Trading.Orders.place/1` for details.
  """
  defdelegate place_order(params), to: Orders, as: :place

  @doc """
  Get all orders.

  See `Alpa.Trading.Orders.list/1` for details.
  """
  defdelegate orders(opts \\ []), to: Orders, as: :list

  @doc """
  Get a specific order.

  See `Alpa.Trading.Orders.get/2` for details.
  """
  defdelegate order(order_id, opts \\ []), to: Orders, as: :get

  @doc """
  Cancel an order.

  See `Alpa.Trading.Orders.cancel/2` for details.
  """
  defdelegate cancel_order(order_id, opts \\ []), to: Orders, as: :cancel

  @doc """
  Cancel all orders.

  See `Alpa.Trading.Orders.cancel_all/1` for details.
  """
  defdelegate cancel_all_orders(opts \\ []), to: Orders, as: :cancel_all

  @doc """
  Place a market buy order.

  See `Alpa.Trading.Orders.buy/3` for details.
  """
  defdelegate buy(symbol, qty, opts \\ []), to: Orders

  @doc """
  Place a market sell order.

  See `Alpa.Trading.Orders.sell/3` for details.
  """
  defdelegate sell(symbol, qty, opts \\ []), to: Orders

  # ============================================================================
  # Positions
  # ============================================================================

  @doc """
  Get all positions.

  See `Alpa.Trading.Positions.list/1` for details.
  """
  defdelegate positions(opts \\ []), to: Positions, as: :list

  @doc """
  Get a specific position.

  See `Alpa.Trading.Positions.get/2` for details.
  """
  defdelegate position(symbol, opts \\ []), to: Positions, as: :get

  @doc """
  Close a position.

  See `Alpa.Trading.Positions.close/2` for details.
  """
  defdelegate close_position(symbol, opts \\ []), to: Positions, as: :close

  @doc """
  Close all positions.

  See `Alpa.Trading.Positions.close_all/1` for details.
  """
  defdelegate close_all_positions(opts \\ []), to: Positions, as: :close_all

  # ============================================================================
  # Assets
  # ============================================================================

  @doc """
  Get all assets.

  See `Alpa.Trading.Assets.list/1` for details.
  """
  defdelegate assets(opts \\ []), to: Assets, as: :list

  @doc """
  Get a specific asset.

  See `Alpa.Trading.Assets.get/2` for details.
  """
  defdelegate asset(symbol, opts \\ []), to: Assets, as: :get

  # ============================================================================
  # Watchlists
  # ============================================================================

  @doc """
  Get all watchlists.

  See `Alpa.Trading.Watchlists.list/1` for details.
  """
  defdelegate watchlists(opts \\ []), to: Watchlists, as: :list

  @doc """
  Get a specific watchlist.

  See `Alpa.Trading.Watchlists.get/2` for details.
  """
  defdelegate watchlist(watchlist_id, opts \\ []), to: Watchlists, as: :get

  @doc """
  Create a watchlist.

  See `Alpa.Trading.Watchlists.create/1` for details.
  """
  defdelegate create_watchlist(params), to: Watchlists, as: :create

  @doc """
  Delete a watchlist.

  See `Alpa.Trading.Watchlists.delete/2` for details.
  """
  defdelegate delete_watchlist(watchlist_id, opts \\ []), to: Watchlists, as: :delete

  # ============================================================================
  # Corporate Actions
  # ============================================================================

  @doc """
  Get corporate action announcements.

  See `Alpa.Trading.CorporateActions.list/1` for details.
  """
  defdelegate corporate_actions(opts \\ []), to: CorporateActions, as: :list

  @doc """
  Get a specific corporate action announcement.

  See `Alpa.Trading.CorporateActions.get/2` for details.
  """
  defdelegate corporate_action(id, opts \\ []), to: CorporateActions, as: :get

  # ============================================================================
  # Market
  # ============================================================================

  @doc """
  Get the market clock.

  See `Alpa.Trading.Market.get_clock/1` for details.
  """
  defdelegate clock(opts \\ []), to: Market, as: :get_clock

  @doc """
  Check if the market is open.

  See `Alpa.Trading.Market.open?/1` for details.
  """
  defdelegate market_open?(opts \\ []), to: Market, as: :open?

  @doc """
  Get the market calendar.

  See `Alpa.Trading.Market.get_calendar/1` for details.
  """
  defdelegate calendar(opts \\ []), to: Market, as: :get_calendar

  # ============================================================================
  # Market Data - Bars
  # ============================================================================

  @doc """
  Get historical bars for a symbol.

  See `Alpa.MarketData.Bars.get/2` for details.
  """
  defdelegate bars(symbol, opts \\ []), to: Bars, as: :get

  @doc """
  Get the latest bar for a symbol.

  See `Alpa.MarketData.Bars.latest/2` for details.
  """
  defdelegate latest_bar(symbol, opts \\ []), to: Bars, as: :latest

  # ============================================================================
  # Market Data - Quotes
  # ============================================================================

  @doc """
  Get historical quotes for a symbol.

  See `Alpa.MarketData.Quotes.get/2` for details.
  """
  defdelegate quotes(symbol, opts \\ []), to: Quotes, as: :get

  @doc """
  Get the latest quote for a symbol.

  See `Alpa.MarketData.Quotes.latest/2` for details.
  """
  defdelegate latest_quote(symbol, opts \\ []), to: Quotes, as: :latest

  # ============================================================================
  # Market Data - Trades
  # ============================================================================

  @doc """
  Get historical trades for a symbol.

  See `Alpa.MarketData.Trades.get/2` for details.
  """
  defdelegate trades(symbol, opts \\ []), to: Trades, as: :get

  @doc """
  Get the latest trade for a symbol.

  See `Alpa.MarketData.Trades.latest/2` for details.
  """
  defdelegate latest_trade(symbol, opts \\ []), to: Trades, as: :latest

  # ============================================================================
  # Market Data - Snapshots
  # ============================================================================

  @doc """
  Get a market snapshot for a symbol.

  See `Alpa.MarketData.Snapshots.get/2` for details.
  """
  defdelegate snapshot(symbol, opts \\ []), to: Snapshots, as: :get

  @doc """
  Get market snapshots for multiple symbols.

  See `Alpa.MarketData.Snapshots.get_multi/2` for details.
  """
  defdelegate snapshots(symbols, opts \\ []), to: Snapshots, as: :get_multi

  # ============================================================================
  # Crypto Market Data
  # ============================================================================

  @doc """
  Get historical crypto bars for a symbol.

  See `Alpa.Crypto.MarketData.bars/2` for details.
  """
  defdelegate crypto_bars(symbol, opts \\ []), to: CryptoMarketData, as: :bars

  @doc """
  Get latest crypto bars for a symbol.

  See `Alpa.Crypto.MarketData.latest_bars/2` for details.
  """
  defdelegate crypto_latest_bars(symbol, opts \\ []), to: CryptoMarketData, as: :latest_bars

  @doc """
  Get historical crypto quotes for a symbol.

  See `Alpa.Crypto.MarketData.quotes/2` for details.
  """
  defdelegate crypto_quotes(symbol, opts \\ []), to: CryptoMarketData, as: :quotes

  @doc """
  Get latest crypto quotes for a symbol.

  See `Alpa.Crypto.MarketData.latest_quotes/2` for details.
  """
  defdelegate crypto_latest_quotes(symbol, opts \\ []), to: CryptoMarketData, as: :latest_quotes

  @doc """
  Get historical crypto trades for a symbol.

  See `Alpa.Crypto.MarketData.trades/2` for details.
  """
  defdelegate crypto_trades(symbol, opts \\ []), to: CryptoMarketData, as: :trades

  @doc """
  Get latest crypto trades for a symbol.

  See `Alpa.Crypto.MarketData.latest_trades/2` for details.
  """
  defdelegate crypto_latest_trades(symbol, opts \\ []), to: CryptoMarketData, as: :latest_trades

  @doc """
  Get crypto snapshots for one or more symbols.

  See `Alpa.Crypto.MarketData.snapshots/2` for details.
  """
  defdelegate crypto_snapshots(symbols, opts \\ []), to: CryptoMarketData, as: :snapshots

  # ============================================================================
  # Crypto Funding
  # ============================================================================

  @doc """
  List crypto wallets.

  See `Alpa.Crypto.Funding.list_wallets/1` for details.
  """
  defdelegate crypto_wallets(opts \\ []), to: Funding, as: :list_wallets

  @doc """
  List crypto funding transfers.

  See `Alpa.Crypto.Funding.list_transfers/1` for details.
  """
  defdelegate crypto_transfers(opts \\ []), to: Funding, as: :list_transfers

  @doc """
  Get a specific crypto transfer.

  See `Alpa.Crypto.Funding.get_transfer/2` for details.
  """
  defdelegate crypto_transfer(id, opts \\ []), to: Funding, as: :get_transfer

  @doc """
  Request a crypto withdrawal.

  See `Alpa.Crypto.Funding.create_transfer/1` for details.
  """
  defdelegate crypto_withdraw(params), to: Funding, as: :create_transfer

  # ============================================================================
  # Crypto Trading
  # ============================================================================

  @doc """
  Get all available crypto assets.

  See `Alpa.Crypto.Trading.assets/1` for details.
  """
  defdelegate crypto_assets(opts \\ []), to: CryptoTrading, as: :assets

  @doc """
  Place a crypto order.

  See `Alpa.Crypto.Trading.place_order/1` for details.
  """
  defdelegate crypto_place_order(params), to: CryptoTrading, as: :place_order

  @doc """
  Buy crypto with a market order.

  See `Alpa.Crypto.Trading.buy/3` for details.
  """
  def crypto_buy(symbol, qty, opts \\ []), do: CryptoTrading.buy(symbol, qty, opts)

  @doc """
  Sell crypto with a market order.

  See `Alpa.Crypto.Trading.sell/3` for details.
  """
  def crypto_sell(symbol, qty, opts \\ []), do: CryptoTrading.sell(symbol, qty, opts)

  @doc """
  Get all crypto positions.

  See `Alpa.Crypto.Trading.positions/1` for details.
  """
  defdelegate crypto_positions(opts \\ []), to: CryptoTrading, as: :positions

  # ============================================================================
  # Options Contracts
  # ============================================================================

  @doc """
  Get option contracts with filtering.

  See `Alpa.Options.Contracts.list/1` for details.
  """
  def option_contracts(opts \\ []), do: OptionsContracts.list(opts)

  @doc """
  Get a specific option contract by symbol or ID.

  See `Alpa.Options.Contracts.get/2` for details.
  """
  def option_contract(symbol_or_id, opts \\ []), do: OptionsContracts.get(symbol_or_id, opts)

  @doc """
  Search for option contracts by underlying symbol.

  See `Alpa.Options.Contracts.search/2` for details.
  """
  defdelegate option_search(underlying_symbol, opts \\ []), to: OptionsContracts, as: :search

  # ============================================================================
  # Account (additional)
  # ============================================================================

  @doc """
  Update account configurations.

  See `Alpa.Trading.Account.update_configurations/1` for details.
  """
  defdelegate update_configurations(settings), to: Account, as: :update_configurations

  @doc """
  Get account activities.

  See `Alpa.Trading.Account.get_activities/1` for details.
  """
  def get_activities(opts \\ []), do: Account.get_activities(opts)

  @doc """
  Get account activities for a specific activity type.

  See `Alpa.Trading.Account.get_activities_by_type/2` for details.
  """
  def get_activities_by_type(activity_type, opts \\ []),
    do: Account.get_activities_by_type(activity_type, opts)

  # ============================================================================
  # Orders (additional)
  # ============================================================================

  @doc """
  Get an order by client order ID.

  See `Alpa.Trading.Orders.get_by_client_id/2` for details.
  """
  def get_order_by_client_id(client_order_id, opts \\ []),
    do: Orders.get_by_client_id(client_order_id, opts)

  @doc """
  Replace (modify) an existing order.

  See `Alpa.Trading.Orders.replace/2` for details.
  """
  defdelegate replace_order(order_id, params), to: Orders, as: :replace

  # ============================================================================
  # Multi-symbol Market Data
  # ============================================================================

  @doc """
  Get historical bars for multiple symbols.

  See `Alpa.MarketData.Bars.get_multi/2` for details.
  """
  def bars_multi(symbols, opts \\ []), do: Bars.get_multi(symbols, opts)

  @doc """
  Get historical quotes for multiple symbols.

  See `Alpa.MarketData.Quotes.get_multi/2` for details.
  """
  def quotes_multi(symbols, opts \\ []), do: Quotes.get_multi(symbols, opts)

  @doc """
  Get historical trades for multiple symbols.

  See `Alpa.MarketData.Trades.get_multi/2` for details.
  """
  def trades_multi(symbols, opts \\ []), do: Trades.get_multi(symbols, opts)

  @doc """
  Get latest bars for multiple symbols.

  See `Alpa.MarketData.Bars.latest_multi/2` for details.
  """
  def latest_bars_multi(symbols, opts \\ []), do: Bars.latest_multi(symbols, opts)

  @doc """
  Get latest quotes for multiple symbols.

  See `Alpa.MarketData.Quotes.latest_multi/2` for details.
  """
  def latest_quotes_multi(symbols, opts \\ []), do: Quotes.latest_multi(symbols, opts)

  @doc """
  Get latest trades for multiple symbols.

  See `Alpa.MarketData.Trades.latest_multi/2` for details.
  """
  def latest_trades_multi(symbols, opts \\ []), do: Trades.latest_multi(symbols, opts)
end
