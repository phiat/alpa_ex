defmodule Alpa.Trading.Watchlists do
  @moduledoc """
  Watchlist operations for the Alpaca Trading API.
  """

  alias Alpa.Client
  alias Alpa.Models.Watchlist

  @doc """
  Get all watchlists.

  ## Examples

      iex> Alpa.Trading.Watchlists.list()
      {:ok, [%Alpa.Models.Watchlist{...}]}

  """
  @spec list(keyword()) :: {:ok, [Watchlist.t()]} | {:error, Alpa.Error.t()}
  def list(opts \\ []) do
    case Client.get("/v2/watchlists", opts) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &Watchlist.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get a specific watchlist by ID.

  ## Examples

      iex> Alpa.Trading.Watchlists.get("watchlist-id")
      {:ok, %Alpa.Models.Watchlist{...}}

  """
  @spec get(String.t(), keyword()) :: {:ok, Watchlist.t()} | {:error, Alpa.Error.t()}
  def get(watchlist_id, opts \\ []) do
    case Client.get("/v2/watchlists/#{watchlist_id}", opts) do
      {:ok, data} -> {:ok, Watchlist.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get a watchlist by name.

  ## Examples

      iex> Alpa.Trading.Watchlists.get_by_name("My Favorites")
      {:ok, %Alpa.Models.Watchlist{...}}

  """
  @spec get_by_name(String.t(), keyword()) :: {:ok, Watchlist.t()} | {:error, Alpa.Error.t()}
  def get_by_name(name, opts \\ []) do
    with {:ok, watchlists} <- list(opts),
         watchlist when not is_nil(watchlist) <- Enum.find(watchlists, &(&1.name == name)) do
      {:ok, watchlist}
    else
      {:error, _} = error -> error
      nil -> {:error, Alpa.Error.from_response(404, %{"message" => "Watchlist '#{name}' not found"})}
    end
  end

  @doc """
  Create a new watchlist.

  ## Parameters

    * `:name` - Watchlist name (required)
    * `:symbols` - List of symbols to add (optional)

  ## Examples

      iex> Alpa.Trading.Watchlists.create(name: "Tech Stocks", symbols: ["AAPL", "MSFT", "GOOGL"])
      {:ok, %Alpa.Models.Watchlist{...}}

  """
  @spec create(keyword()) :: {:ok, Watchlist.t()} | {:error, Alpa.Error.t()}
  def create(params) when is_list(params) do
    body = %{
      name: Keyword.fetch!(params, :name),
      symbols: Keyword.get(params, :symbols, [])
    }

    case Client.post("/v2/watchlists", body, params) do
      {:ok, data} -> {:ok, Watchlist.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Update a watchlist.

  ## Parameters

    * `:name` - New watchlist name (optional)
    * `:symbols` - New list of symbols (replaces existing, optional)

  ## Examples

      iex> Alpa.Trading.Watchlists.update("watchlist-id", name: "Renamed Watchlist")
      {:ok, %Alpa.Models.Watchlist{...}}

  """
  @spec update(String.t(), keyword()) :: {:ok, Watchlist.t()} | {:error, Alpa.Error.t()}
  def update(watchlist_id, params) when is_list(params) do
    body =
      params
      |> Keyword.take([:name, :symbols])
      |> Map.new()

    case Client.put("/v2/watchlists/#{watchlist_id}", body, params) do
      {:ok, data} -> {:ok, Watchlist.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Delete a watchlist.

  ## Examples

      iex> Alpa.Trading.Watchlists.delete("watchlist-id")
      {:ok, :deleted}

  """
  @spec delete(String.t(), keyword()) :: {:ok, :deleted} | {:error, Alpa.Error.t()}
  def delete(watchlist_id, opts \\ []) do
    Client.delete("/v2/watchlists/#{watchlist_id}", opts)
  end

  @doc """
  Add a symbol to a watchlist.

  ## Examples

      iex> Alpa.Trading.Watchlists.add_symbol("watchlist-id", "NVDA")
      {:ok, %Alpa.Models.Watchlist{...}}

  """
  @spec add_symbol(String.t(), String.t(), keyword()) ::
          {:ok, Watchlist.t()} | {:error, Alpa.Error.t()}
  def add_symbol(watchlist_id, symbol, opts \\ []) do
    body = %{symbol: symbol}

    case Client.post("/v2/watchlists/#{watchlist_id}", body, opts) do
      {:ok, data} -> {:ok, Watchlist.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Remove a symbol from a watchlist.

  ## Examples

      iex> Alpa.Trading.Watchlists.remove_symbol("watchlist-id", "NVDA")
      {:ok, %Alpa.Models.Watchlist{...}}

  """
  @spec remove_symbol(String.t(), String.t(), keyword()) ::
          {:ok, Watchlist.t()} | {:error, Alpa.Error.t()}
  def remove_symbol(watchlist_id, symbol, opts \\ []) do
    case Client.delete("/v2/watchlists/#{watchlist_id}/#{symbol}", opts) do
      {:ok, data} when is_map(data) -> {:ok, Watchlist.from_map(data)}
      {:ok, :deleted} -> {:ok, :deleted}
      {:error, _} = error -> error
    end
  end
end
