defmodule Alpa.Trading.Positions do
  @moduledoc """
  Position operations for the Alpaca Trading API.
  """

  alias Alpa.Client
  alias Alpa.Models.Position

  @doc """
  Get all open positions.

  ## Examples

      iex> Alpa.Trading.Positions.list()
      {:ok, [%Alpa.Models.Position{...}]}

  """
  @spec list(keyword()) :: {:ok, [Position.t()]} | {:error, Alpa.Error.t()}
  def list(opts \\ []) do
    case Client.get("/v2/positions", opts) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &Position.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get a specific position by symbol or asset ID.

  ## Examples

      iex> Alpa.Trading.Positions.get("AAPL")
      {:ok, %Alpa.Models.Position{...}}

  """
  @spec get(String.t(), keyword()) :: {:ok, Position.t()} | {:error, Alpa.Error.t()}
  def get(symbol_or_asset_id, opts \\ []) do
    encoded_symbol = URI.encode_www_form(symbol_or_asset_id)

    case Client.get("/v2/positions/#{encoded_symbol}", opts) do
      {:ok, data} -> {:ok, Position.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Close a position by symbol or asset ID.

  ## Options

    * `:qty` - Number of shares to close (partial close)
    * `:percentage` - Percentage of position to close (0-100)

  If neither is specified, closes the entire position.

  ## Examples

      # Close entire position
      iex> Alpa.Trading.Positions.close("AAPL")
      {:ok, %Alpa.Models.Order{...}}

      # Close 50% of position
      iex> Alpa.Trading.Positions.close("AAPL", percentage: 50)
      {:ok, %Alpa.Models.Order{...}}

      # Close 10 shares
      iex> Alpa.Trading.Positions.close("AAPL", qty: 10)
      {:ok, %Alpa.Models.Order{...}}

  """
  @spec close(String.t(), keyword()) :: {:ok, Alpa.Models.Order.t()} | {:error, Alpa.Error.t()}
  def close(symbol_or_asset_id, opts \\ []) do
    encoded_symbol = URI.encode_www_form(symbol_or_asset_id)

    params =
      opts
      |> Keyword.take([:qty, :percentage])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    opts = if map_size(params) > 0, do: Keyword.put(opts, :params, params), else: opts

    case Client.delete("/v2/positions/#{encoded_symbol}", opts) do
      {:ok, data} when is_map(data) -> {:ok, Alpa.Models.Order.from_map(data)}
      {:ok, :deleted} -> {:ok, :deleted}
      {:error, _} = error -> error
    end
  end

  @doc """
  Close all open positions.

  ## Options

    * `:cancel_orders` - Also cancel all open orders (boolean, default: false)

  ## Examples

      iex> Alpa.Trading.Positions.close_all()
      {:ok, [%{"symbol" => "AAPL", "status" => 200, "body" => %{...}}, ...]}

  """
  @spec close_all(keyword()) :: {:ok, [map()]} | {:error, Alpa.Error.t()}
  def close_all(opts \\ []) do
    params =
      case Keyword.get(opts, :cancel_orders) do
        true -> %{cancel_orders: true}
        _ -> %{}
      end

    opts = if map_size(params) > 0, do: Keyword.put(opts, :params, params), else: opts

    Client.delete("/v2/positions", opts)
  end
end
