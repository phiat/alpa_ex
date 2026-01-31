defmodule Alpa.Resource do
  @moduledoc """
  A macro that generates standard CRUD functions for Alpaca API resources.

  This reduces boilerplate for simple endpoints while preserving the typed
  return pattern used throughout the SDK. All generated functions return
  `{:ok, Model.t()}` or `{:error, Alpa.Error.t()}` tuples.

  ## Usage

      defmodule Alpa.Trading.Assets do
        use Alpa.Resource,
          base_path: "/v2/assets",
          model: Alpa.Models.Asset,
          operations: [:list, :get]
      end

  ## Options

    * `:base_path` - The API path prefix (e.g., `"/v2/assets"`). Required.
    * `:model` - The model module that implements `from_map/1`. Required.
    * `:operations` - List of operations to generate. Required.
      Supported: `:list`, `:get`, `:create`, `:update`, `:delete`.
    * `:id_field` - Name for the ID parameter in generated docs and
      function signatures. Default: `:id`.
    * `:client` - Which API base URL to use: `:trading` or `:data`.
      Default: `:trading`.

  ## Generated functions

  Depending on the operations specified:

    * `list/0`, `list/1` - List resources. Returns `{:ok, [Model.t()]} | {:error, Alpa.Error.t()}`.
    * `get/1`, `get/2` - Get a single resource by ID. Returns `{:ok, Model.t()} | {:error, Alpa.Error.t()}`.
    * `create/1` - Create a resource. Returns `{:ok, Model.t()} | {:error, Alpa.Error.t()}`.
    * `update/2` - Update a resource by ID. Returns `{:ok, Model.t()} | {:error, Alpa.Error.t()}`.
    * `delete/1`, `delete/2` - Delete a resource by ID. Returns `{:ok, :deleted} | {:error, Alpa.Error.t()}`.

  This macro is **optional** and intended for new endpoints or simple CRUD
  resources. Existing modules do not need to be changed.
  """

  defmacro __using__(opts) do
    base_path = Keyword.fetch!(opts, :base_path)
    model = Keyword.fetch!(opts, :model)
    operations = Keyword.fetch!(opts, :operations)
    id_field = Keyword.get(opts, :id_field, :id)
    client = Keyword.get(opts, :client, :trading)

    # Validate operations at compile time
    valid_ops = [:list, :get, :create, :update, :delete]

    invalid = operations -- valid_ops

    if invalid != [] do
      raise ArgumentError,
            "Invalid operations: #{inspect(invalid)}. Must be one of #{inspect(valid_ops)}"
    end

    get_fn =
      case client do
        :data -> :get_data
        :trading -> :get
      end

    quote do
      alias Alpa.Client
      alias Alpa.Error

      unquote(if :list in operations, do: gen_list(base_path, model, get_fn))
      unquote(if :get in operations, do: gen_get(base_path, model, id_field, get_fn))
      unquote(if :create in operations, do: gen_create(base_path, model))
      unquote(if :update in operations, do: gen_update(base_path, model, id_field))
      unquote(if :delete in operations, do: gen_delete(base_path, id_field))
    end
  end

  defp gen_list(base_path, model, get_fn) do
    quote do
      @doc """
      List all resources.

      Accepts keyword options for query parameters and client configuration.
      """
      @spec list(keyword()) :: {:ok, [unquote(model).t()]} | {:error, Error.t()}
      def list(opts \\ []) do
        {params, rest} = Keyword.pop(opts, :params, %{})

        call_opts =
          if params == %{}, do: rest, else: Keyword.put(rest, :params, params)

        case Client.unquote(get_fn)(unquote(base_path), call_opts) do
          {:ok, data} when is_list(data) ->
            {:ok, Enum.map(data, &unquote(model).from_map/1)}

          {:ok, unexpected} ->
            {:error, Error.invalid_response(unexpected)}

          {:error, _} = error ->
            error
        end
      end
    end
  end

  defp gen_get(base_path, model, id_field, get_fn) do
    quote do
      @doc """
      Get a single resource by #{unquote(id_field)}.
      """
      @spec get(String.t(), keyword()) :: {:ok, unquote(model).t()} | {:error, Error.t()}
      def get(unquote(Macro.var(id_field, nil)), opts \\ []) do
        path =
          unquote(base_path) <>
            "/" <> URI.encode_www_form(to_string(unquote(Macro.var(id_field, nil))))

        case Client.unquote(get_fn)(path, opts) do
          {:ok, data} -> {:ok, unquote(model).from_map(data)}
          {:error, _} = error -> error
        end
      end
    end
  end

  defp gen_create(base_path, model) do
    quote do
      @doc """
      Create a new resource.

      Accepts a keyword list or map of attributes.
      """
      @spec create(keyword() | map()) :: {:ok, unquote(model).t()} | {:error, Error.t()}
      def create(params) when is_list(params) do
        create(Map.new(params))
      end

      def create(params) when is_map(params) do
        case Client.post(unquote(base_path), params) do
          {:ok, data} -> {:ok, unquote(model).from_map(data)}
          {:error, _} = error -> error
        end
      end
    end
  end

  defp gen_update(base_path, model, id_field) do
    quote do
      @doc """
      Update a resource by #{unquote(id_field)}.

      Accepts a keyword list or map of attributes to update.
      """
      @spec update(String.t(), keyword() | map()) ::
              {:ok, unquote(model).t()} | {:error, Error.t()}
      def update(unquote(Macro.var(id_field, nil)), params) when is_list(params) do
        update(unquote(Macro.var(id_field, nil)), Map.new(params))
      end

      def update(unquote(Macro.var(id_field, nil)), params) when is_map(params) do
        path =
          unquote(base_path) <>
            "/" <> URI.encode_www_form(to_string(unquote(Macro.var(id_field, nil))))

        case Client.put(path, params) do
          {:ok, data} -> {:ok, unquote(model).from_map(data)}
          {:error, _} = error -> error
        end
      end
    end
  end

  defp gen_delete(base_path, id_field) do
    quote do
      @doc """
      Delete a resource by #{unquote(id_field)}.
      """
      @spec delete(String.t(), keyword()) :: {:ok, :deleted} | {:error, Error.t()}
      def delete(unquote(Macro.var(id_field, nil)), opts \\ []) do
        path =
          unquote(base_path) <>
            "/" <> URI.encode_www_form(to_string(unquote(Macro.var(id_field, nil))))

        Client.delete(path, opts)
      end
    end
  end
end
