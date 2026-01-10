defmodule Alpa.Error do
  @moduledoc """
  Error types for the Alpa client.

  All API errors are wrapped in an `Alpa.Error` struct with
  structured information about what went wrong.
  """

  @type t :: %__MODULE__{
          type: error_type(),
          message: String.t(),
          code: integer() | nil,
          details: map() | nil
        }

  @type error_type ::
          :unauthorized
          | :forbidden
          | :not_found
          | :unprocessable_entity
          | :rate_limited
          | :server_error
          | :network_error
          | :timeout
          | :invalid_response
          | :missing_credentials
          | :unknown

  defstruct [:type, :message, :code, :details]

  @doc """
  Create an error from an HTTP response.
  """
  @spec from_response(integer(), map() | String.t()) :: t()
  def from_response(status, body) when is_map(body) do
    %__MODULE__{
      type: type_from_status(status),
      message: Map.get(body, "message", "Unknown error"),
      code: Map.get(body, "code") || status,
      details: body
    }
  end

  def from_response(status, body) when is_binary(body) do
    %__MODULE__{
      type: type_from_status(status),
      message: body,
      code: status,
      details: nil
    }
  end

  @doc """
  Create a network/connection error.
  """
  @spec network_error(term()) :: t()
  def network_error(reason) do
    %__MODULE__{
      type: :network_error,
      message: "Network error: #{inspect(reason)}",
      code: nil,
      details: %{reason: reason}
    }
  end

  @doc """
  Create a timeout error.
  """
  @spec timeout_error() :: t()
  def timeout_error do
    %__MODULE__{
      type: :timeout,
      message: "Request timed out",
      code: nil,
      details: nil
    }
  end

  @doc """
  Create an invalid response error.
  """
  @spec invalid_response(term()) :: t()
  def invalid_response(reason) do
    %__MODULE__{
      type: :invalid_response,
      message: "Invalid response: #{inspect(reason)}",
      code: nil,
      details: %{reason: reason}
    }
  end

  @doc """
  Create a missing credentials error.
  """
  @spec missing_credentials() :: t()
  def missing_credentials do
    %__MODULE__{
      type: :missing_credentials,
      message: "API credentials not configured. Set APCA_API_KEY_ID and APCA_API_SECRET_KEY",
      code: nil,
      details: nil
    }
  end

  # Private helpers

  defp type_from_status(401), do: :unauthorized
  defp type_from_status(403), do: :forbidden
  defp type_from_status(404), do: :not_found
  defp type_from_status(422), do: :unprocessable_entity
  defp type_from_status(429), do: :rate_limited
  defp type_from_status(status) when status >= 500, do: :server_error
  defp type_from_status(_), do: :unknown
end

defimpl String.Chars, for: Alpa.Error do
  def to_string(%Alpa.Error{type: type, message: message, code: code}) do
    code_str = if code, do: " (#{code})", else: ""
    "[#{type}]#{code_str} #{message}"
  end
end
