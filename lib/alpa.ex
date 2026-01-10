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

  ## Configuration

  Configuration can be set via:

  1. Environment variables (recommended for credentials)
  2. Application config
  3. Options passed directly to functions

  See `Alpa.Config` for details.
  """

  alias Alpa.Trading.{Account, Orders, Positions, Assets, Watchlists, Market}
  alias Alpa.MarketData.{Bars, Quotes, Trades, Snapshots}

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
end
