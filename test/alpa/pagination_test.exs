defmodule Alpa.PaginationTest do
  use ExUnit.Case, async: true

  alias Alpa.Pagination

  describe "all/2" do
    test "fetches single page when no next_page_token" do
      fetch_fn = fn _opts ->
        {:ok,
         %{"bars" => [%{"t" => "2024-01-01"}, %{"t" => "2024-01-02"}], "next_page_token" => nil}}
      end

      assert {:ok, items} = Pagination.all(fetch_fn, data_key: "bars")
      assert length(items) == 2
      assert [%{"t" => "2024-01-01"}, %{"t" => "2024-01-02"}] = items
    end

    test "paginates through multiple pages with next_page_token" do
      # Track calls with an agent to simulate stateful pagination
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      fetch_fn = fn opts ->
        call_num = Agent.get_and_update(agent, fn n -> {n, n + 1} end)

        page_token =
          get_in(opts, [:params, :page_token]) ||
            get_in(opts, [:params]) |> maybe_get_page_token()

        case call_num do
          0 ->
            assert page_token == nil
            {:ok, %{"bars" => [%{"id" => 1}, %{"id" => 2}], "next_page_token" => "token_page2"}}

          1 ->
            assert page_token == "token_page2"
            {:ok, %{"bars" => [%{"id" => 3}, %{"id" => 4}], "next_page_token" => "token_page3"}}

          2 ->
            assert page_token == "token_page3"
            {:ok, %{"bars" => [%{"id" => 5}], "next_page_token" => nil}}
        end
      end

      assert {:ok, items} = Pagination.all(fetch_fn, data_key: "bars")
      assert length(items) == 5
      assert Enum.map(items, & &1["id"]) == [1, 2, 3, 4, 5]

      Agent.stop(agent)
    end

    test "respects max_pages option" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      fetch_fn = fn _opts ->
        call_num = Agent.get_and_update(agent, fn n -> {n, n + 1} end)
        {:ok, %{"bars" => [%{"id" => call_num}], "next_page_token" => "token_#{call_num + 1}"}}
      end

      assert {:ok, items} = Pagination.all(fetch_fn, data_key: "bars", max_pages: 3)
      assert length(items) == 3

      Agent.stop(agent)
    end

    test "handles plain list responses (no pagination)" do
      fetch_fn = fn _opts ->
        {:ok, [%{"id" => 1}, %{"id" => 2}]}
      end

      assert {:ok, items} = Pagination.all(fetch_fn)
      assert length(items) == 2
    end

    test "handles empty list response" do
      fetch_fn = fn _opts ->
        {:ok, []}
      end

      assert {:ok, []} = Pagination.all(fetch_fn)
    end

    test "handles empty data in map response" do
      fetch_fn = fn _opts ->
        {:ok, %{"bars" => [], "next_page_token" => nil}}
      end

      assert {:ok, []} = Pagination.all(fetch_fn, data_key: "bars")
    end

    test "returns error when first page fails" do
      fetch_fn = fn _opts ->
        {:error, %{message: "unauthorized"}}
      end

      assert {:error, %{message: "unauthorized"}} = Pagination.all(fetch_fn, data_key: "bars")
    end

    test "returns partial results when later page fails" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      fetch_fn = fn _opts ->
        call_num = Agent.get_and_update(agent, fn n -> {n, n + 1} end)

        case call_num do
          0 -> {:ok, %{"bars" => [%{"id" => 1}], "next_page_token" => "token2"}}
          1 -> {:error, %{message: "rate limited"}}
        end
      end

      assert {:ok, items} = Pagination.all(fetch_fn, data_key: "bars")
      assert length(items) == 1

      Agent.stop(agent)
    end

    test "passes params through and adds page_token to map params" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      fetch_fn = fn opts ->
        call_num = Agent.get_and_update(agent, fn n -> {n, n + 1} end)
        params = Keyword.get(opts, :params, %{})

        case call_num do
          0 ->
            assert params == %{timeframe: "1Day"}
            {:ok, %{"bars" => [%{"id" => 1}], "next_page_token" => "abc123"}}

          1 ->
            assert params[:page_token] == "abc123"
            assert params[:timeframe] == "1Day"
            {:ok, %{"bars" => [%{"id" => 2}], "next_page_token" => nil}}
        end
      end

      assert {:ok, items} =
               Pagination.all(fetch_fn, data_key: "bars", params: %{timeframe: "1Day"})

      assert length(items) == 2

      Agent.stop(agent)
    end

    test "auto-detects data in map when no data_key given" do
      fetch_fn = fn _opts ->
        {:ok, %{"items" => [%{"id" => 1}, %{"id" => 2}], "next_page_token" => nil}}
      end

      assert {:ok, items} = Pagination.all(fetch_fn)
      assert length(items) == 2
    end
  end

  describe "stream/2" do
    test "streams single page" do
      fetch_fn = fn _opts ->
        {:ok, %{"bars" => [%{"id" => 1}, %{"id" => 2}], "next_page_token" => nil}}
      end

      items = Pagination.stream(fetch_fn, data_key: "bars") |> Enum.to_list()
      assert length(items) == 2
      assert [%{"id" => 1}, %{"id" => 2}] = items
    end

    test "streams across multiple pages" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      fetch_fn = fn _opts ->
        call_num = Agent.get_and_update(agent, fn n -> {n, n + 1} end)

        case call_num do
          0 -> {:ok, %{"bars" => [%{"id" => 1}, %{"id" => 2}], "next_page_token" => "page2"}}
          1 -> {:ok, %{"bars" => [%{"id" => 3}], "next_page_token" => nil}}
        end
      end

      items = Pagination.stream(fetch_fn, data_key: "bars") |> Enum.to_list()
      assert length(items) == 3
      assert Enum.map(items, & &1["id"]) == [1, 2, 3]

      Agent.stop(agent)
    end

    test "stream can be lazily consumed with take" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      fetch_fn = fn _opts ->
        call_num = Agent.get_and_update(agent, fn n -> {n, n + 1} end)

        {:ok,
         %{
           "items" => [%{"id" => call_num * 2 + 1}, %{"id" => call_num * 2 + 2}],
           "next_page_token" => "page_#{call_num + 1}"
         }}
      end

      items = Pagination.stream(fetch_fn, data_key: "items") |> Stream.take(3) |> Enum.to_list()
      assert length(items) == 3
      assert Enum.map(items, & &1["id"]) == [1, 2, 3]

      # Only 2 pages should have been fetched (first page has 2 items, second page has 2 items but we only take 3)
      total_calls = Agent.get(agent, & &1)
      assert total_calls == 2

      Agent.stop(agent)
    end

    test "stream handles plain list responses" do
      fetch_fn = fn _opts ->
        {:ok, [%{"id" => 1}, %{"id" => 2}]}
      end

      items = Pagination.stream(fetch_fn) |> Enum.to_list()
      assert [%{"id" => 1}, %{"id" => 2}] = items
    end

    test "stream handles error on first page" do
      fetch_fn = fn _opts ->
        {:error, %{message: "unauthorized"}}
      end

      items = Pagination.stream(fetch_fn, data_key: "bars") |> Enum.to_list()
      assert items == []
    end

    test "stream stops on error during pagination" do
      {:ok, agent} = Agent.start_link(fn -> 0 end)

      fetch_fn = fn _opts ->
        call_num = Agent.get_and_update(agent, fn n -> {n, n + 1} end)

        case call_num do
          0 -> {:ok, %{"bars" => [%{"id" => 1}], "next_page_token" => "page2"}}
          1 -> {:error, %{message: "server error"}}
        end
      end

      items = Pagination.stream(fetch_fn, data_key: "bars") |> Enum.to_list()
      assert items == [%{"id" => 1}]

      Agent.stop(agent)
    end

    test "stream handles empty response" do
      fetch_fn = fn _opts ->
        {:ok, %{"bars" => [], "next_page_token" => nil}}
      end

      items = Pagination.stream(fetch_fn, data_key: "bars") |> Enum.to_list()
      assert items == []
    end
  end

  # Helper to extract page_token from various param formats
  defp maybe_get_page_token(nil), do: nil
  defp maybe_get_page_token(%{page_token: token}), do: token
  defp maybe_get_page_token(%{}), do: nil
  defp maybe_get_page_token(params) when is_list(params), do: Keyword.get(params, :page_token)
end
