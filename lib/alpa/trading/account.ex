defmodule Alpa.Trading.Account do
  @moduledoc """
  Account operations for the Alpaca Trading API.
  """

  alias Alpa.Client
  alias Alpa.Models.Account
  alias Alpa.Models.AccountConfig
  alias Alpa.Models.Activity
  alias Alpa.Models.PortfolioHistory

  @doc """
  Get account information.

  Returns the current account state including buying power,
  cash, portfolio value, and trading status.

  ## Examples

      iex> Alpa.Trading.Account.get()
      {:ok, %Alpa.Models.Account{...}}

  """
  @spec get(keyword()) :: {:ok, Account.t()} | {:error, Alpa.Error.t()}
  def get(opts \\ []) do
    case Client.get("/v2/account", opts) do
      {:ok, data} -> {:ok, Account.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get account configurations.

  Returns configuration settings like day trade margin call handling,
  trade confirmation emails, and trading restrictions.

  ## Examples

      iex> Alpa.Trading.Account.get_configurations()
      {:ok, %{
        "dtbp_check" => "entry",
        "trade_confirm_email" => "all",
        "suspend_trade" => false,
        "no_shorting" => false,
        "fractional_trading" => true,
        "max_margin_multiplier" => "4",
        "pdt_check" => "entry",
        "ptp_no_exception_entry" => false
      }}

  """
  @spec get_configurations(keyword()) :: {:ok, AccountConfig.t()} | {:error, Alpa.Error.t()}
  def get_configurations(opts \\ []) do
    case Client.get("/v2/account/configurations", opts) do
      {:ok, data} -> {:ok, AccountConfig.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Update account configurations.

  ## Options

    * `:dtbp_check` - Day trade buying power check ("both", "entry", "exit")
    * `:trade_confirm_email` - Trade confirmation emails ("all", "none")
    * `:suspend_trade` - Suspend trading (boolean)
    * `:no_shorting` - Disable shorting (boolean)
    * `:fractional_trading` - Enable fractional trading (boolean)
    * `:max_margin_multiplier` - Max margin multiplier ("1", "2", "4")
    * `:pdt_check` - Pattern day trader check ("entry", "exit", "both")
    * `:ptp_no_exception_entry` - PTP no exception entry (boolean)

  ## Examples

      iex> Alpa.Trading.Account.update_configurations(suspend_trade: true)
      {:ok, %{...}}

  """
  @spec update_configurations(keyword()) :: {:ok, map()} | {:error, Alpa.Error.t()}
  def update_configurations(settings) when is_list(settings) do
    body =
      settings
      |> Keyword.take([
        :dtbp_check,
        :trade_confirm_email,
        :suspend_trade,
        :no_shorting,
        :fractional_trading,
        :max_margin_multiplier,
        :pdt_check,
        :ptp_no_exception_entry
      ])
      |> Map.new(fn {k, v} -> {to_string(k), v} end)

    case Client.patch("/v2/account/configurations", body, settings) do
      {:ok, data} -> {:ok, AccountConfig.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get account activities.

  Returns a list of account activities like fills, dividends, and fees.

  ## Options

    * `:activity_types` - List of activity types to filter (e.g., ["FILL", "DIV"])
    * `:date` - Date to filter (format: "YYYY-MM-DD")
    * `:until` - Filter activities until this time
    * `:after` - Filter activities after this time
    * `:direction` - Sort direction ("asc" or "desc")
    * `:page_size` - Number of results per page (max 100)
    * `:page_token` - Pagination token

  ## Examples

      iex> Alpa.Trading.Account.get_activities(activity_types: ["FILL"])
      {:ok, [%{...}]}

  """
  @spec get_activities(keyword()) :: {:ok, [Activity.t()]} | {:error, Alpa.Error.t()}
  def get_activities(opts \\ []) do
    params =
      opts
      |> Keyword.take([:activity_types, :date, :until, :after, :direction, :page_size, :page_token])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.map(fn
        {:activity_types, types} when is_list(types) -> {:activity_types, Enum.join(types, ",")}
        other -> other
      end)
      |> Map.new()

    case Client.get("/v2/account/activities", Keyword.put(opts, :params, params)) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &Activity.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get account activities for a specific activity type.

  ## Activity Types

  Common types: "FILL", "TRANS", "MISC", "ACATC", "ACATS", "CSD", "CSW",
  "DIV", "JNLC", "JNLS", "MA", "NC", "OPASN", "OPEXP", "OPXRC", "PTC", "PTR", "SSO", "SSP"

  ## Options

    * `:date` - Date to filter (format: "YYYY-MM-DD")
    * `:until` - Filter activities until this time
    * `:after` - Filter activities after this time
    * `:direction` - Sort direction ("asc" or "desc")
    * `:page_size` - Number of results per page (max 100)
    * `:page_token` - Pagination token

  ## Examples

      iex> Alpa.Trading.Account.get_activities_by_type("FILL")
      {:ok, [%{...}]}

  """
  @spec get_activities_by_type(String.t(), keyword()) :: {:ok, [Activity.t()]} | {:error, Alpa.Error.t()}
  def get_activities_by_type(activity_type, opts \\ []) do
    params =
      opts
      |> Keyword.take([:date, :until, :after, :direction, :page_size, :page_token])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Client.get("/v2/account/activities/#{URI.encode_www_form(activity_type)}", Keyword.put(opts, :params, params)) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &Activity.from_map/1)}
      {:ok, unexpected} -> {:error, Alpa.Error.invalid_response(unexpected)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get portfolio history.

  Returns historical portfolio values over a time period.

  ## Options

    * `:period` - Time period ("1D", "1W", "1M", "3M", "1A", "all", "intraday")
    * `:timeframe` - Resolution ("1Min", "5Min", "15Min", "1H", "1D")
    * `:intraday_reporting` - Intraday reporting type ("market_hours", "extended_hours", "continuous")
    * `:start` - Start date (format: "YYYY-MM-DD")
    * `:end` - End date (format: "YYYY-MM-DD")
    * `:pnl_reset` - Reset PnL calculations ("per_day")
    * `:date_end` - Deprecated, use :end instead

  ## Examples

      iex> Alpa.Trading.Account.get_portfolio_history(period: "1M", timeframe: "1D")
      {:ok, %{
        "timestamp" => [...],
        "equity" => [...],
        "profit_loss" => [...],
        "profit_loss_pct" => [...],
        "base_value" => 100000.0,
        "timeframe" => "1D"
      }}

  """
  @spec get_portfolio_history(keyword()) :: {:ok, PortfolioHistory.t()} | {:error, Alpa.Error.t()}
  def get_portfolio_history(opts \\ []) do
    params =
      opts
      |> Keyword.take([:period, :timeframe, :intraday_reporting, :start, :end, :pnl_reset, :date_end])
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Client.get("/v2/account/portfolio/history", Keyword.put(opts, :params, params)) do
      {:ok, data} -> {:ok, PortfolioHistory.from_map(data)}
      {:error, _} = error -> error
    end
  end
end
