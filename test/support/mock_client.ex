defmodule Alpa.Test.MockClient do
  @moduledoc """
  Test helper for mocking Alpa.Client responses.

  Uses :meck to stub Client functions so API module tests
  can verify parameter building and response parsing without
  making real HTTP requests.
  """

  @doc """
  Set up mocking for Alpa.Client.

  Call this in your test setup block. Returns `:ok`.
  Remember to call `teardown/0` in an `on_exit` callback.
  """
  def setup do
    :meck.new(Alpa.Client, [:passthrough])
    :ok
  end

  @doc """
  Tear down the mock. Safe to call even if not mocked.
  """
  def teardown do
    try do
      :meck.unload(Alpa.Client)
    rescue
      _ -> :ok
    catch
      _, _ -> :ok
    end
  end

  @doc """
  Stub a GET request to return the given response data.
  """
  def mock_get(path, response) do
    :meck.expect(Alpa.Client, :get, fn p, _opts ->
      if p == path,
        do: response,
        else: {:error, Alpa.Error.from_response(404, %{"message" => "Unexpected path: #{p}"})}
    end)
  end

  @doc """
  Stub a POST request to return the given response data.
  """
  def mock_post(path, response) do
    :meck.expect(Alpa.Client, :post, fn p, _body, _opts ->
      if p == path,
        do: response,
        else: {:error, Alpa.Error.from_response(404, %{"message" => "Unexpected path: #{p}"})}
    end)
  end

  @doc """
  Stub a PUT request to return the given response data.
  """
  def mock_put(path, response) do
    :meck.expect(Alpa.Client, :put, fn p, _body, _opts ->
      if p == path,
        do: response,
        else: {:error, Alpa.Error.from_response(404, %{"message" => "Unexpected path: #{p}"})}
    end)
  end

  @doc """
  Stub a DELETE request to return the given response data.
  """
  def mock_delete(path, response) do
    :meck.expect(Alpa.Client, :delete, fn p, _opts ->
      if p == path,
        do: response,
        else: {:error, Alpa.Error.from_response(404, %{"message" => "Unexpected path: #{p}"})}
    end)
  end

  @doc """
  Stub a GET request to the data API to return the given response data.
  """
  def mock_get_data(path, response) do
    :meck.expect(Alpa.Client, :get_data, fn p, _opts ->
      if p == path,
        do: response,
        else: {:error, Alpa.Error.from_response(404, %{"message" => "Unexpected path: #{p}"})}
    end)
  end
end
