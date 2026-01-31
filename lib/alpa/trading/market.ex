defmodule Alpa.Trading.Market do
  @moduledoc """
  Market clock and calendar operations for the Alpaca Trading API.
  """

  alias Alpa.Client
  alias Alpa.Models.Calendar
  alias Alpa.Models.Clock

  @doc """
  Get the current market clock.

  Returns whether the market is open and the next open/close times.

  ## Examples

      iex> Alpa.Trading.Market.get_clock()
      {:ok, %Alpa.Models.Clock{
        timestamp: ~U[2024-01-15 14:30:00Z],
        is_open: true,
        next_open: ~U[2024-01-16 14:30:00Z],
        next_close: ~U[2024-01-15 21:00:00Z]
      }}

  """
  @spec get_clock(keyword()) :: {:ok, Clock.t()} | {:error, Alpa.Error.t()}
  def get_clock(opts \\ []) do
    case Client.get("/v2/clock", opts) do
      {:ok, data} -> {:ok, Clock.from_map(data)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Check if the market is currently open.

  ## Examples

      iex> Alpa.Trading.Market.open?()
      {:ok, true}

  """
  @spec open?(keyword()) :: {:ok, boolean()} | {:error, Alpa.Error.t()}
  def open?(opts \\ []) do
    case get_clock(opts) do
      {:ok, %Clock{is_open: is_open}} -> {:ok, is_open}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get the market calendar.

  Returns trading days and their open/close times for a date range.

  ## Options

    * `:start` - Start date (format: "YYYY-MM-DD" or Date)
    * `:end` - End date (format: "YYYY-MM-DD" or Date)

  ## Examples

      iex> Alpa.Trading.Market.get_calendar(start: ~D[2024-01-01], end: ~D[2024-01-31])
      {:ok, [
        %{"date" => "2024-01-02", "open" => "09:30", "close" => "16:00", ...},
        ...
      ]}

  """
  @spec get_calendar(keyword()) :: {:ok, [Calendar.t()]} | {:error, Alpa.Error.t()}
  def get_calendar(opts \\ []) do
    params =
      opts
      |> Keyword.take([:start, :end])
      |> Enum.map(fn
        {k, %Date{} = d} -> {k, Date.to_string(d)}
        other -> other
      end)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    case Client.get("/v2/calendar", Keyword.put(opts, :params, params)) do
      {:ok, data} when is_list(data) -> {:ok, Enum.map(data, &Calendar.from_map/1)}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get the next market open time.

  ## Examples

      iex> Alpa.Trading.Market.next_open()
      {:ok, ~U[2024-01-16 14:30:00Z]}

  """
  @spec next_open(keyword()) :: {:ok, DateTime.t()} | {:error, Alpa.Error.t()}
  def next_open(opts \\ []) do
    case get_clock(opts) do
      {:ok, %Clock{next_open: next_open}} -> {:ok, next_open}
      {:error, _} = error -> error
    end
  end

  @doc """
  Get the next market close time.

  ## Examples

      iex> Alpa.Trading.Market.next_close()
      {:ok, ~U[2024-01-15 21:00:00Z]}

  """
  @spec next_close(keyword()) :: {:ok, DateTime.t()} | {:error, Alpa.Error.t()}
  def next_close(opts \\ []) do
    case get_clock(opts) do
      {:ok, %Clock{next_close: next_close}} -> {:ok, next_close}
      {:error, _} = error -> error
    end
  end
end
