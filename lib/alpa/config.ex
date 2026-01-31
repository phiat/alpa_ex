defmodule Alpa.Config do
  @moduledoc """
  Configuration management for the Alpa client.

  Configuration can be provided via:
  1. Application config (config/runtime.exs recommended)
  2. Environment variables
  3. Explicit options passed to functions

  ## Environment Variables

      APCA_API_KEY_ID      - Your Alpaca API key
      APCA_API_SECRET_KEY  - Your Alpaca API secret
      APCA_USE_PAPER       - "true" for paper trading (default), "false" for live

  ## Application Config

      config :alpa_ex,
        api_key: "your-key",
        api_secret: "your-secret",
        use_paper: true

  ## Priority (highest to lowest)

  1. Options passed directly to functions
  2. Environment variables
  3. Application config
  """

  @type t :: %__MODULE__{
          api_key: String.t() | nil,
          api_secret: String.t() | nil,
          trading_url: String.t(),
          data_url: String.t(),
          use_paper: boolean(),
          timeout: pos_integer(),
          receive_timeout: pos_integer()
        }

  defstruct [
    :api_key,
    :api_secret,
    trading_url: "https://api.alpaca.markets",
    data_url: "https://data.alpaca.markets",
    use_paper: true,
    timeout: 30_000,
    receive_timeout: 30_000
  ]

  @doc """
  Build configuration from application config and options.

  Options override application config values.

  ## Options

    * `:api_key` - Alpaca API key (required for authenticated requests)
    * `:api_secret` - Alpaca API secret (required for authenticated requests)
    * `:use_paper` - Use paper trading endpoint (default: true)
    * `:timeout` - Request timeout in milliseconds (default: 30_000)
    * `:receive_timeout` - Response receive timeout in milliseconds (default: 30_000)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    trading_url = get_trading_url(opts)

    use_paper =
      if Keyword.has_key?(opts, :trading_url) do
        String.contains?(trading_url, "paper")
      else
        get_opt(opts, :use_paper, true)
      end

    %__MODULE__{
      api_key: get_opt(opts, :api_key),
      api_secret: get_opt(opts, :api_secret),
      trading_url: trading_url,
      data_url: get_opt(opts, :data_url, "https://data.alpaca.markets"),
      use_paper: use_paper,
      timeout: get_opt(opts, :timeout, 30_000),
      receive_timeout: get_opt(opts, :receive_timeout, 30_000)
    }
  end

  @default_trading_url "https://api.alpaca.markets"

  @doc """
  Get the base trading URL based on paper/live mode.

  If a custom `trading_url` (different from the default) was explicitly set,
  it is used regardless of the `use_paper` flag. Otherwise, `use_paper: true`
  resolves to the paper trading URL.
  """
  @spec trading_url(t()) :: String.t()
  def trading_url(%__MODULE__{trading_url: url}), do: url

  @doc """
  Get the market data URL.
  """
  @spec data_url(t()) :: String.t()
  def data_url(%__MODULE__{data_url: url}), do: url

  @doc """
  Check if configuration has valid credentials.
  """
  @spec has_credentials?(t()) :: boolean()
  def has_credentials?(%__MODULE__{api_key: key, api_secret: secret}) do
    is_binary(key) and byte_size(key) > 0 and
      is_binary(secret) and byte_size(secret) > 0
  end

  # Private helpers

  defp get_opt(opts, key, default \\ nil) do
    with :error <- Keyword.fetch(opts, key),
         nil <- get_from_env(key),
         nil <- Application.get_env(:alpa_ex, key) do
      default
    else
      {:ok, value} -> value
      value when not is_nil(value) -> value
    end
  end

  defp get_from_env(:api_key), do: System.get_env("APCA_API_KEY_ID")
  defp get_from_env(:api_secret), do: System.get_env("APCA_API_SECRET_KEY")

  defp get_from_env(:use_paper) do
    case System.get_env("APCA_USE_PAPER") do
      "false" -> false
      "true" -> true
      _ -> nil
    end
  end

  defp get_from_env(_), do: nil

  defp get_trading_url(opts) do
    case Keyword.fetch(opts, :trading_url) do
      {:ok, url} ->
        url

      :error ->
        use_paper = get_opt(opts, :use_paper, true)

        if use_paper do
          paper_url()
        else
          @default_trading_url
        end
    end
  end

  defp paper_url do
    Application.get_env(:alpa_ex, :paper_url, "https://paper-api.alpaca.markets")
  end
end

defimpl Inspect, for: Alpa.Config do
  import Inspect.Algebra

  def inspect(%Alpa.Config{} = config, opts) do
    redacted = %{
      config
      | api_key: if(config.api_key, do: "***", else: nil),
        api_secret: if(config.api_secret, do: "***", else: nil)
    }

    concat(["#Alpa.Config<", to_doc(Map.from_struct(redacted), opts), ">"])
  end
end
