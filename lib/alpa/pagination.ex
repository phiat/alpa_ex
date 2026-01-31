defmodule Alpa.Pagination do
  @moduledoc """
  Pagination helpers for Alpaca API list endpoints.

  Fetches results from paginated endpoints. Currently supports single-page
  fetching with configurable limits. Multi-page token-based pagination
  will be added when API functions are updated to return `next_page_token`.

  ## Usage

      # Fetch results (respects :limit option)
      {:ok, orders} = Alpa.Pagination.all(&Alpa.Trading.Orders.list/1, status: "closed", limit: 500)

      # Stream results lazily
      Alpa.Pagination.stream(&Alpa.Trading.Orders.list/1, status: "closed")
      |> Stream.take(100)
      |> Enum.to_list()

  ## Limitations

  Alpaca's API uses `next_page_token` for pagination, but the SDK's API
  functions currently return only the parsed results without the token.
  Until the response format is extended to include pagination metadata,
  `all/2` and `stream/2` fetch a single page per call. Use the `:limit`
  option to control how many results are returned.
  """

  @doc """
  Fetch all results from a paginated endpoint.

  Calls the given function with the provided options and returns all results.

  ## Parameters

    * `fetch_fn` - A function that accepts a keyword list of options
      and returns `{:ok, results}` or `{:error, error}`
    * `opts` - Options to pass to the fetch function

  ## Examples

      iex> Alpa.Pagination.all(&Alpa.Trading.Orders.list/1, status: "closed", limit: 500)
      {:ok, [%Alpa.Models.Order{}, ...]}

  """
  @spec all((keyword() -> {:ok, list()} | {:error, term()}), keyword()) ::
          {:ok, list()} | {:error, term()}
  def all(fetch_fn, opts \\ []) do
    case fetch_fn.(opts) do
      {:ok, results} when is_list(results) -> {:ok, results}
      {:ok, other} -> {:ok, other}
      {:error, _} = error -> error
    end
  end

  @doc """
  Create a lazy stream of results from a paginated endpoint.

  Returns a `Stream` that fetches a page on demand. Each element
  in the stream is an individual result item (not a page).

  ## Examples

      Alpa.Pagination.stream(&Alpa.Trading.Orders.list/1, status: "closed")
      |> Stream.take(50)
      |> Enum.each(&IO.inspect/1)

  """
  @spec stream((keyword() -> {:ok, list()} | {:error, term()}), keyword()) :: Enumerable.t()
  def stream(fetch_fn, opts \\ []) do
    Stream.resource(
      fn -> :initial end,
      fn
        :done ->
          {:halt, :done}

        :initial ->
          case fetch_fn.(opts) do
            {:ok, [_ | _] = results} ->
              {results, :done}

            {:ok, _} ->
              {:halt, :done}

            {:error, _} ->
              {:halt, :done}
          end
      end,
      fn _state -> :ok end
    )
  end
end
