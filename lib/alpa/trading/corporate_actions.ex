defmodule Alpa.Trading.CorporateActions do
  @moduledoc """
  Corporate actions operations for the Alpaca Trading API.

  Provides access to corporate action announcements including
  dividends, mergers, spinoffs, and stock splits.
  """

  alias Alpa.Client
  alias Alpa.Models.CorporateAction

  @doc """
  Get corporate action announcements.

  ## Options

    * `:ca_types` - Filter by type (e.g., ["dividend", "split"])
    * `:since` - Filter since date (format: "YYYY-MM-DD")
    * `:until` - Filter until date (format: "YYYY-MM-DD")
    * `:symbol` - Filter by symbol
    * `:cusip` - Filter by CUSIP
    * `:date_type` - Date type to filter on ("declaration", "ex", "record", "payable")

  ## Examples

      iex> Alpa.Trading.CorporateActions.list(ca_types: ["dividend"], symbol: "AAPL")
      {:ok, [%Alpa.Models.CorporateAction{...}]}

  """
  @spec list(keyword()) :: {:ok, [CorporateAction.t()]} | {:error, Alpa.Error.t()}
  def list(opts \\ []) do
    params =
      opts
      |> Keyword.take([:ca_types, :since, :until, :symbol, :cusip, :date_type])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.map(fn
        {:ca_types, types} when is_list(types) -> {:ca_types, Enum.join(types, ",")}
        other -> other
      end)
      |> Map.new()

    case Client.get("/v2/corporate_actions/announcements", Keyword.put(opts, :params, params)) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &CorporateAction.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get a specific corporate action announcement.

  ## Examples

      iex> Alpa.Trading.CorporateActions.get("announcement-id")
      {:ok, %Alpa.Models.CorporateAction{...}}

  """
  @spec get(String.t(), keyword()) :: {:ok, CorporateAction.t()} | {:error, Alpa.Error.t()}
  def get(announcement_id, opts \\ []) do
    case Client.get("/v2/corporate_actions/announcements/#{announcement_id}", opts) do
      {:ok, data} -> {:ok, CorporateAction.from_map(data)}
      {:error, _} = error -> error
    end
  end
end
