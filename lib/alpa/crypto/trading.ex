defmodule Alpa.Crypto.Trading do
  @moduledoc """
  Cryptocurrency trading operations for the Alpaca Trading API.

  Alpaca supports commission-free crypto trading for select pairs.

  ## Supported Pairs

  Common pairs include BTC/USD, ETH/USD, and others.
  Use `Alpa.assets(asset_class: "crypto")` to get the full list.

  ## Notes

  - Crypto trades 24/7
  - Fractional trading is supported
  - Order types: market, limit
  - Time in force: gtc, ioc, fok
  """

  alias Alpa.Client
  alias Alpa.Models.{Asset, Order, Position}

  @doc """
  Get all available crypto assets.

  ## Examples

      iex> Alpa.Crypto.Trading.assets()
      {:ok, [%Alpa.Models.Asset{class: :crypto, symbol: "BTC/USD", ...}]}

  """
  @spec assets(keyword()) :: {:ok, [Asset.t()]} | {:error, Alpa.Error.t()}
  def assets(opts \\ []) do
    params = Map.put(%{}, :asset_class, "crypto")

    case Client.get("/v2/assets", Keyword.put(opts, :params, params)) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &Asset.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get a specific crypto asset.

  ## Examples

      iex> Alpa.Crypto.Trading.asset("BTC/USD")
      {:ok, %Alpa.Models.Asset{...}}

  """
  @spec asset(String.t(), keyword()) :: {:ok, Asset.t()} | {:error, Alpa.Error.t()}
  def asset(symbol, opts \\ []) do
    case Client.get("/v2/assets/#{URI.encode_www_form(symbol)}", opts) do
      {:ok, data} -> {:ok, Asset.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get all crypto positions.

  ## Examples

      iex> Alpa.Crypto.Trading.positions()
      {:ok, [%Alpa.Models.Position{...}]}

  """
  @spec positions(keyword()) :: {:ok, [Position.t()]} | {:error, Alpa.Error.t()}
  def positions(opts \\ []) do
    case Client.get("/v2/positions", opts) do
      {:ok, data} when is_list(data) ->
        crypto_positions =
          data
          |> Enum.filter(fn p -> p["asset_class"] == "crypto" end)
          |> Enum.map(&Position.from_map/1)

        {:ok, crypto_positions}

      {:ok, unexpected} ->
        {:error, Alpa.Error.invalid_response(unexpected)}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Get a specific crypto position.

  ## Examples

      iex> Alpa.Crypto.Trading.position("BTC/USD")
      {:ok, %Alpa.Models.Position{...}}

  """
  @spec position(String.t(), keyword()) :: {:ok, Position.t()} | {:error, Alpa.Error.t()}
  def position(symbol, opts \\ []) do
    case Client.get("/v2/positions/#{URI.encode_www_form(symbol)}", opts) do
      {:ok, data} -> {:ok, Position.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Place a crypto order.

  ## Required Parameters

    * `:symbol` - Crypto pair symbol (e.g., "BTC/USD")
    * `:side` - "buy" or "sell"
    * `:type` - "market" or "limit"
    * `:time_in_force` - "gtc", "ioc", or "fok"

  ## Quantity (one required)

    * `:qty` - Quantity in base currency (e.g., 0.5 for 0.5 BTC)
    * `:notional` - Dollar amount to trade

  ## Optional Parameters

    * `:limit_price` - Required for limit orders
    * `:client_order_id` - Custom order ID

  ## Examples

      # Buy $100 worth of Bitcoin
      iex> Alpa.Crypto.Trading.place_order(
      ...>   symbol: "BTC/USD",
      ...>   notional: "100",
      ...>   side: "buy",
      ...>   type: "market",
      ...>   time_in_force: "gtc"
      ...> )
      {:ok, %Alpa.Models.Order{...}}

      # Limit order to buy 0.1 BTC at $40,000
      iex> Alpa.Crypto.Trading.place_order(
      ...>   symbol: "BTC/USD",
      ...>   qty: "0.1",
      ...>   side: "buy",
      ...>   type: "limit",
      ...>   limit_price: "40000",
      ...>   time_in_force: "gtc"
      ...> )
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec place_order(keyword()) :: {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def place_order(params) when is_list(params) do
    body =
      params
      |> Keyword.take([
        :symbol,
        :qty,
        :notional,
        :side,
        :type,
        :time_in_force,
        :limit_price,
        :client_order_id
      ])
      |> Map.new()

    case Client.post("/v2/orders", body, params) do
      {:ok, data} -> {:ok, Order.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Buy crypto with a market order.

  ## Examples

      # Buy 0.01 BTC
      iex> Alpa.Crypto.Trading.buy("BTC/USD", "0.01")
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec buy(String.t(), String.t(), keyword()) :: {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def buy(symbol, qty, opts \\ []) do
    place_order(
      Keyword.merge(opts,
        symbol: symbol,
        qty: qty,
        side: "buy",
        type: "market",
        time_in_force: "gtc"
      )
    )
  end

  @doc """
  Sell crypto with a market order.

  ## Examples

      iex> Alpa.Crypto.Trading.sell("BTC/USD", "0.01")
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec sell(String.t(), String.t(), keyword()) :: {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def sell(symbol, qty, opts \\ []) do
    place_order(
      Keyword.merge(opts,
        symbol: symbol,
        qty: qty,
        side: "sell",
        type: "market",
        time_in_force: "gtc"
      )
    )
  end

  @doc """
  Buy crypto by dollar amount.

  ## Examples

      # Buy $50 worth of ETH
      iex> Alpa.Crypto.Trading.buy_notional("ETH/USD", "50")
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec buy_notional(String.t(), String.t(), keyword()) ::
          {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def buy_notional(symbol, amount, opts \\ []) do
    place_order(
      Keyword.merge(opts,
        symbol: symbol,
        notional: amount,
        side: "buy",
        type: "market",
        time_in_force: "gtc"
      )
    )
  end

  @doc """
  Sell crypto by dollar amount.

  ## Examples

      iex> Alpa.Crypto.Trading.sell_notional("ETH/USD", "50")
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec sell_notional(String.t(), String.t(), keyword()) ::
          {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def sell_notional(symbol, amount, opts \\ []) do
    place_order(
      Keyword.merge(opts,
        symbol: symbol,
        notional: amount,
        side: "sell",
        type: "market",
        time_in_force: "gtc"
      )
    )
  end
end
