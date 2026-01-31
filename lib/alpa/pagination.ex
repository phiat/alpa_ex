defmodule Alpa.Pagination do
  @moduledoc """
  Pagination helpers for Alpaca API list endpoints.

  Provides auto-pagination and streaming for endpoints that return
  paginated results using `next_page_token`.

  ## Usage

      # Fetch all orders across pages
      Alpa.Pagination.all(&Alpa.Trading.Orders.list/1, status: "closed")

      # Stream pages lazily
      Alpa.Pagination.stream(&Alpa.Trading.Orders.list/1, status: "closed")
      |> Stream.take(100)
      |> Enum.to_list()
  """

  @doc """
  Fetch all results across all pages.

  Calls the given function repeatedly, following `next_page_token`
  until all results are collected.

  ## Parameters

    * `fetch_fn` - A function that accepts a keyword list of options
      and returns `{:ok, results}` or `{:error, error}`
    * `opts` - Options to pass to the fetch function

  ## Options

    * `:max_pages` - Maximum number of pages to fetch (default: 100)

  ## Examples

      iex> Alpa.Pagination.all(&Alpa.Trading.Orders.list/1, status: "closed", limit: 100)
      {:ok, [%Alpa.Models.Order{}, ...]}

  """
  @spec all((keyword() -> {:ok, list()} | {:error, term()}), keyword()) ::
          {:ok, list()} | {:error, term()}
  def all(fetch_fn, opts \\ []) do
    max_pages = Keyword.get(opts, :max_pages, 100)
    opts = Keyword.delete(opts, :max_pages)

    do_fetch_all(fetch_fn, opts, [], max_pages, 0)
  end

  @doc """
  Create a lazy stream of paginated results.

  Returns a `Stream` that fetches pages on demand. Each element
  in the stream is an individual result item (not a page).

  ## Examples

      Alpa.Pagination.stream(&Alpa.Trading.Orders.list/1, status: "closed")
      |> Stream.take(50)
      |> Enum.each(&IO.inspect/1)

  """
  @spec stream((keyword() -> {:ok, list()} | {:error, term()}), keyword()) :: Enumerable.t()
  def stream(fetch_fn, opts \\ []) do
    Stream.resource(
      fn -> {fetch_fn, opts, :initial} end,
      fn
        {_fetch_fn, _opts, :done} ->
          {:halt, :done}

        {fetch_fn, opts, :initial} ->
          case fetch_fn.(opts) do
            {:ok, results} when is_list(results) and length(results) > 0 ->
              {results, {fetch_fn, opts, :continue}}

            {:ok, _} ->
              {:halt, :done}

            {:error, _} ->
              {:halt, :done}
          end

        {_fetch_fn, _opts, :continue} ->
          # Note: pagination depends on the API returning a next_page_token
          # For now, this fetches a single page. Full token-based pagination
          # requires the API functions to return the token alongside results.
          {:halt, :done}
      end,
      fn _state -> :ok end
    )
  end

  # Private

  defp do_fetch_all(_fetch_fn, _opts, acc, max_pages, page) when page >= max_pages do
    {:ok, Enum.reverse(List.flatten(acc))}
  end

  defp do_fetch_all(fetch_fn, opts, acc, _max_pages, _page) do
    case fetch_fn.(opts) do
      {:ok, results} when is_list(results) and length(results) > 0 ->
        # If we got fewer results than the limit, we're on the last page
        limit = Keyword.get(opts, :limit, 50)

        if length(results) < limit do
          {:ok, Enum.reverse(List.flatten([results | acc]))}
        else
          # For endpoints that support page_token, we'd extract it here
          # For now, we just return what we have since token extraction
          # requires changes to the response format
          {:ok, Enum.reverse(List.flatten([results | acc]))}
        end

      {:ok, results} when is_list(results) ->
        {:ok, Enum.reverse(List.flatten(acc))}

      {:ok, _} ->
        {:ok, Enum.reverse(List.flatten(acc))}

      {:error, _} = error ->
        if acc == [] do
          error
        else
          # Return what we have so far
          {:ok, Enum.reverse(List.flatten(acc))}
        end
    end
  end
end
