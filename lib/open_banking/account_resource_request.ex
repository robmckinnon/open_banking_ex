defmodule OpenBanking.AccountResourceRequest do
  @moduledoc """
  For performing HTTP GET call to an Account API resource endpoint.
  """
  require Logger

  alias OpenBanking.{ApiConfig, SslConfig}

  @application_json "application/json; charset=utf-8"

  @doc """
  Get Account API resource from given resource_endpoint.
  Returns {:ok, response} or {:error, error}.
  """
  def get_account_resource(
        resource_endpoint,
        access_token,
        fapi_financial_id,
        key_path,
        cert_path
      ) do
    HTTPoison.request(
      :get,
      resource_endpoint,
      "",
      [
        {"Content-Type", @application_json},
        {"Accept", @application_json},
        {"Authorization", "Bearer #{access_token}"},
        {"x-fapi-financial-id", fapi_financial_id}
      ],
      ssl: SslConfig.ssl_config(cert_path, key_path)
    )
  end

  @doc """
  Get Account API resource from given resource_endpoint.
  Returns response or raises Error.
  """
  def request_account_resource(
        resource_endpoint,
        access_token,
        config = %ApiConfig{}
      )
      when is_binary(access_token) and is_binary(resource_endpoint) do
    case get_account_resource(
           resource_endpoint,
           access_token,
           config.fapi_financial_id,
           config.transport_key_file,
           config.transport_cert_file
         ) do
      {:ok, response} ->
        response

      {:error, error = %HTTPoison.Error{reason: reason}} ->
        Logger.warn(inspect(error))
        raise inspect(reason)
    end
  end
end
