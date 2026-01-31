defmodule Alpa.Pagination do
  @moduledoc """
  Pagination helpers for Alpaca API list endpoints.

  Fetches results from paginated endpoints. Currently supports single-page
  fetching with configurable limits. Multi-page token-based pagination
  will be added when API functions are updated to return `next_page_token`.

  The fetch function should return `{:ok, result}` where result is either:
  - A map containing a `"next_page_token"` key (raw API response format) and
    data under a known key. The data key is specified via the `:data_key` option.
  - A plain list (single-page result, no further pagination).

  ## Usage

      # Fetch results (respects :limit option)
      {:ok, orders} = Alpa.Pagination.all(&Alpa.Trading.Orders.list/1, status: "closed", limit: 500)

      # Fetch all bars across pages using raw API responses
      Alpa.Pagination.all(
        fn opts ->
          Alpa.Client.get_data("/v2/stocks/AAPL/bars", opts)
        end,
        data_key: "bars",
        params: %{timeframe: "1Day", start: "2024-01-01T00:00:00Z"}
      )

      # Stream pages lazily
      Alpa.Pagination.stream(
        fn opts ->
          Alpa.Client.get_data("/v2/stocks/AAPL/bars", opts)
        end,
        data_key: "bars",
        params: %{timeframe: "1Day", start: "2024-01-01T00:00:00Z"}
      )
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
      and returns `{:ok, results}` or `{:error, error}`. The results
      can be a map (with `"next_page_token"`) or a plain list.
    * `opts` - Options to pass to the fetch function

  ## Options

    * `:max_pages` - Maximum number of pages to fetch (default: 100)
    * `:data_key` - The key in the response map that holds the data list
      (e.g., `"bars"`, `"trades"`, `"quotes"`, `"orders"`). Required when
      working with map responses that contain `next_page_token`.

  ## Examples

      iex> Alpa.Pagination.all(&Alpa.Trading.Orders.list/1, status: "closed", limit: 500)
      {:ok, [%Alpa.Models.Order{}, ...]}

      iex> Alpa.Pagination.all(
      ...>   fn opts -> Alpa.Client.get_data("/v2/stocks/AAPL/bars", opts) end,
      ...>   data_key: "bars",
      ...>   params: %{timeframe: "1Day"}
      ...> )
      {:ok, [%{"t" => "...", "o" => 150.0, ...}, ...]}

  """
  @spec all((keyword() -> {:ok, map() | list()} | {:error, term()}), keyword()) ::
          {:ok, list()} | {:error, term()}
  def all(fetch_fn, opts \\ []) do
    max_pages = Keyword.get(opts, :max_pages, 100)
    data_key = Keyword.get(opts, :data_key)
    opts = opts |> Keyword.delete(:max_pages) |> Keyword.delete(:data_key)

    do_fetch_all(fetch_fn, opts, data_key, [], max_pages, 0)
  end

  @doc """
  Create a lazy stream of results from a paginated endpoint.

  Returns a `Stream` that fetches a page on demand. Each element
  in the stream is an individual result item (not a page).

  ## Options

    * `:data_key` - The key in the response map that holds the data list.
      Required for map responses with `next_page_token`.

  ## Examples

      Alpa.Pagination.stream(
        fn opts -> Alpa.Client.get_data("/v2/stocks/AAPL/bars", opts) end,
        data_key: "bars",
        params: %{timeframe: "1Day"}
      )
      |> Stream.take(50)
      |> Enum.each(&IO.inspect/1)

  """
  @spec stream((keyword() -> {:ok, map() | list()} | {:error, term()}), keyword()) ::
          Enumerable.t()
  def stream(fetch_fn, opts \\ []) do
    data_key = Keyword.get(opts, :data_key)
    opts = Keyword.delete(opts, :data_key)

    Stream.resource(
      fn -> {fetch_fn, opts, data_key, :initial} end,
      &stream_next/1,
      fn _state -> :ok end
    )
  end

  # Stream implementation

  defp stream_next({_fetch_fn, _opts, _data_key, :done}) do
    {:halt, :done}
  end

  defp stream_next({fetch_fn, opts, data_key, :initial}) do
    case fetch_fn.(opts) do
      {:ok, %{} = response} ->
        {items, next_token} = extract_page(response, data_key)

        case {items, next_token} do
          {[_ | _], token} when is_binary(token) ->
            next_opts = add_page_token(opts, token)
            {items, {fetch_fn, next_opts, data_key, :continue}}

          {[_ | _], _} ->
            {items, {fetch_fn, opts, data_key, :done}}

          _ ->
            {:halt, :done}
        end

      {:ok, [_ | _] = results} ->
        {results, {fetch_fn, opts, data_key, :done}}

      {:ok, _} ->
        {:halt, :done}

      {:error, _} ->
        {:halt, :done}
    end
  end

  defp stream_next({fetch_fn, opts, data_key, :continue}) do
    case fetch_fn.(opts) do
      {:ok, %{} = response} ->
        {items, next_token} = extract_page(response, data_key)

        case {items, next_token} do
          {[_ | _], token} when is_binary(token) ->
            next_opts = add_page_token(opts, token)
            {items, {fetch_fn, next_opts, data_key, :continue}}

          {[_ | _], _} ->
            {items, {fetch_fn, opts, data_key, :done}}

          _ ->
            {:halt, :done}
        end

      {:ok, [_ | _] = results} ->
        {results, {fetch_fn, opts, data_key, :done}}

      {:ok, _} ->
        {:halt, :done}

      {:error, _} ->
        {:halt, :done}
    end
  end

  # Private helpers

  defp do_fetch_all(_fetch_fn, _opts, _data_key, acc, max_pages, page) when page >= max_pages do
    {:ok, acc |> Enum.reverse() |> List.flatten()}
  end

  defp do_fetch_all(fetch_fn, opts, data_key, acc, max_pages, page) do
    case fetch_fn.(opts) do
      {:ok, %{} = response} ->
        {items, next_token} = extract_page(response, data_key)

        new_acc =
          case items do
            [_ | _] -> [items | acc]
            _ -> acc
          end

        case next_token do
          token when is_binary(token) ->
            next_opts = add_page_token(opts, token)
            do_fetch_all(fetch_fn, next_opts, data_key, new_acc, max_pages, page + 1)

          _ ->
            {:ok, new_acc |> Enum.reverse() |> List.flatten()}
        end

      {:ok, [_ | _] = results} ->
        {:ok, [results | acc] |> Enum.reverse() |> List.flatten()}

      {:ok, results} when is_list(results) ->
        {:ok, acc |> Enum.reverse() |> List.flatten()}

      {:ok, _} ->
        {:ok, acc |> Enum.reverse() |> List.flatten()}

      {:error, _} = error ->
        if acc == [] do
          error
        else
          {:ok, acc |> Enum.reverse() |> List.flatten()}
        end
    end
  end

  defp extract_page(response, data_key) do
    next_token = Map.get(response, "next_page_token")

    items =
      if data_key do
        case Map.get(response, data_key) do
          items when is_list(items) -> items
          _ -> []
        end
      else
        # Try to find the data list automatically by looking for list values
        # excluding the "next_page_token" key
        response
        |> Map.drop(["next_page_token"])
        |> Map.values()
        |> Enum.find([], &is_list/1)
      end

    {items, next_token}
  end

  defp add_page_token(opts, token) do
    case Keyword.get(opts, :params) do
      %{} = params ->
        Keyword.put(opts, :params, Map.put(params, :page_token, token))

      nil ->
        Keyword.put(opts, :params, %{page_token: token})

      params when is_list(params) ->
        Keyword.put(opts, :params, Keyword.put(params, :page_token, token))
    end
  end
end
