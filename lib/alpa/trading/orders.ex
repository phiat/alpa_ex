defmodule Alpa.Trading.Orders do
  @moduledoc """
  Order operations for the Alpaca Trading API.
  """

  alias Alpa.Client
  alias Alpa.Models.Order

  @doc """
  Place a new order.

  ## Required Parameters

    * `:symbol` - Symbol or asset ID to trade
    * `:side` - "buy" or "sell"
    * `:type` - "market", "limit", "stop", "stop_limit", "trailing_stop"
    * `:time_in_force` - "day", "gtc", "opg", "cls", "ioc", "fok"

  ## Quantity (one required)

    * `:qty` - Number of shares (integer or decimal string)
    * `:notional` - Dollar amount to trade (for fractional trading)

  ## Optional Parameters

    * `:limit_price` - Limit price (required for limit/stop_limit)
    * `:stop_price` - Stop price (required for stop/stop_limit)
    * `:trail_price` - Trail price in dollars (for trailing_stop)
    * `:trail_percent` - Trail percent (for trailing_stop)
    * `:extended_hours` - Allow trading in extended hours (boolean)
    * `:client_order_id` - Custom order ID (max 48 chars)
    * `:order_class` - "simple", "bracket", "oco", "oto"
    * `:take_profit` - Take profit config for bracket orders
    * `:stop_loss` - Stop loss config for bracket orders

  ## Examples

      # Market order
      iex> Alpa.Trading.Orders.place(symbol: "AAPL", qty: 10, side: "buy", type: "market", time_in_force: "day")
      {:ok, %Alpa.Models.Order{...}}

      # Limit order
      iex> Alpa.Trading.Orders.place(symbol: "AAPL", qty: 10, side: "buy", type: "limit", limit_price: "150.00", time_in_force: "gtc")
      {:ok, %Alpa.Models.Order{...}}

      # Bracket order
      iex> Alpa.Trading.Orders.place(
      ...>   symbol: "AAPL",
      ...>   qty: 10,
      ...>   side: "buy",
      ...>   type: "market",
      ...>   time_in_force: "day",
      ...>   order_class: "bracket",
      ...>   take_profit: %{limit_price: "160.00"},
      ...>   stop_loss: %{stop_price: "140.00", limit_price: "139.00"}
      ...> )
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec place(keyword()) :: {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def place(params) when is_list(params) do
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
        :stop_price,
        :trail_price,
        :trail_percent,
        :extended_hours,
        :client_order_id,
        :order_class,
        :take_profit,
        :stop_loss
      ])
      |> Map.new()

    case Client.post("/v2/orders", body, params) do
      {:ok, data} -> {:ok, Order.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get all orders.

  ## Options

    * `:status` - Order status ("open", "closed", "all")
    * `:limit` - Max number of orders (default 50, max 500)
    * `:after` - Filter orders after this timestamp
    * `:until` - Filter orders until this timestamp
    * `:direction` - Sort direction ("asc", "desc")
    * `:nested` - Include nested orders (boolean)
    * `:symbols` - List of symbols to filter

  ## Examples

      iex> Alpa.Trading.Orders.list(status: "open")
      {:ok, [%Alpa.Models.Order{...}]}

  """
  @spec list(keyword()) :: {:ok, [Order.t()]} | {:error, Alpa.Error.t()}
  def list(opts \\ []) do
    params =
      opts
      |> Keyword.take([:status, :limit, :after, :until, :direction, :nested, :symbols])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.map(fn
        {:symbols, syms} when is_list(syms) -> {:symbols, Enum.join(syms, ",")}
        other -> other
      end)
      |> Map.new()

    case Client.get("/v2/orders", Keyword.put(opts, :params, params)) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &Order.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get an order by ID.

  ## Examples

      iex> Alpa.Trading.Orders.get("order-id-here")
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec get(String.t(), keyword()) :: {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def get(order_id, opts \\ []) do
    case Client.get("/v2/orders/#{order_id}", opts) do
      {:ok, data} -> {:ok, Order.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get an order by client order ID.

  ## Examples

      iex> Alpa.Trading.Orders.get_by_client_id("my-custom-id")
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec get_by_client_id(String.t(), keyword()) :: {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def get_by_client_id(client_order_id, opts \\ []) do
    params = %{client_order_id: client_order_id}

    case Client.get("/v2/orders:by_client_order_id", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, Order.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Replace (modify) an existing order.

  ## Parameters

    * `:qty` - New quantity
    * `:time_in_force` - New time in force
    * `:limit_price` - New limit price
    * `:stop_price` - New stop price
    * `:trail` - New trail amount
    * `:client_order_id` - New client order ID

  ## Examples

      iex> Alpa.Trading.Orders.replace("order-id", qty: 20, limit_price: "155.00")
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec replace(String.t(), keyword()) :: {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def replace(order_id, params) when is_list(params) do
    body =
      params
      |> Keyword.take([:qty, :time_in_force, :limit_price, :stop_price, :trail, :client_order_id])
      |> Map.new()

    case Client.patch("/v2/orders/#{order_id}", body, params) do
      {:ok, data} -> {:ok, Order.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Cancel an order by ID.

  ## Examples

      iex> Alpa.Trading.Orders.cancel("order-id")
      {:ok, :deleted}

  """
  @spec cancel(String.t(), keyword()) :: {:ok, :deleted} | {:error, Alpa.Error.t()}
  def cancel(order_id, opts \\ []) do
    Client.delete("/v2/orders/#{order_id}", opts)
  end

  @doc """
  Cancel all open orders.

  ## Examples

      iex> Alpa.Trading.Orders.cancel_all()
      {:ok, [%{"id" => "...", "status" => 200}, ...]}

  """
  @spec cancel_all(keyword()) :: {:ok, [map()]} | {:error, Alpa.Error.t()}
  def cancel_all(opts \\ []) do
    Client.delete("/v2/orders", opts)
  end

  @doc """
  Helper to place a market buy order.
  """
  @spec buy(String.t(), pos_integer() | String.t(), keyword()) ::
          {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def buy(symbol, qty, opts \\ []) do
    place(
      Keyword.merge(opts,
        symbol: symbol,
        qty: qty,
        side: "buy",
        type: "market",
        time_in_force: "day"
      )
    )
  end

  @doc """
  Helper to place a market sell order.
  """
  @spec sell(String.t(), pos_integer() | String.t(), keyword()) ::
          {:ok, Order.t()} | {:error, Alpa.Error.t()}
  def sell(symbol, qty, opts \\ []) do
    place(
      Keyword.merge(opts,
        symbol: symbol,
        qty: qty,
        side: "sell",
        type: "market",
        time_in_force: "day"
      )
    )
  end
end
