defmodule OpenBanking.AccountResourceRequest do
  @moduledoc """
  For performing HTTP GET call to an Account API resource endpoint.
  """
  require Logger

  alias OpenBanking.SslConfig

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
        client_id,
        resource_endpoint,
        access_token,
        fapi_financial_id,
        transport_key_file \\ "./certificates/transport.key",
        transport_cert_file \\ "./certificates/transport.pem"
      )
      when is_binary(resource_endpoint) and is_binary(client_id) and is_binary(access_token) do
    case get_account_resource(
           resource_endpoint,
           access_token,
           fapi_financial_id,
           transport_key_file,
           transport_cert_file
         ) do
      {:ok, response} ->
        response

      {:error, error = %HTTPoison.Error{reason: reason}} ->
        Logger.warn(inspect(error))
        raise inspect(reason)
    end
  end
end
