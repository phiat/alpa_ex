defmodule Alpa.Trading.CorporateActions do
  @moduledoc """
  Corporate actions operations for the Alpaca Trading API.

  Provides access to corporate action announcements including
  dividends, mergers, spinoffs, and stock splits.
  """

  alias Alpa.Client

  @doc """
  List corporate action announcements.

  ## Options

    * `:ca_types` - List of types: "dividend", "merger", "spinoff", "split"
    * `:since` - Filter announcements since date (YYYY-MM-DD)
    * `:until` - Filter announcements until date (YYYY-MM-DD)
    * `:symbol` - Filter by symbol
    * `:cusip` - Filter by CUSIP
    * `:date_type` - Date type for since/until filter ("declaration", "ex", "record", "payable")

  ## Examples

      iex> Alpa.Trading.CorporateActions.list_announcements(ca_types: ["dividend"], symbol: "AAPL")
      {:ok, [%{...}]}

  """
  @spec list_announcements(keyword()) :: {:ok, [map()]} | {:error, Alpa.Error.t()}
  def list_announcements(opts \\ []) do
    params =
      opts
      |> Keyword.take([:ca_types, :since, :until, :symbol, :cusip, :date_type])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.map(fn
        {:ca_types, types} when is_list(types) -> {:ca_types, Enum.join(types, ",")}
        other -> other
      end)
      |> Map.new()

    Client.get("/v2/corporate_actions/announcements", Keyword.put(opts, :params, params))
  end

  @doc """
  Get a specific corporate action announcement by ID.

  ## Examples

      iex> Alpa.Trading.CorporateActions.get_announcement("announcement-id")
      {:ok, %{...}}

  """
  @spec get_announcement(String.t(), keyword()) :: {:ok, map()} | {:error, Alpa.Error.t()}
  def get_announcement(announcement_id, opts \\ []) do
    Client.get("/v2/corporate_actions/announcements/#{announcement_id}", opts)
  end
end
