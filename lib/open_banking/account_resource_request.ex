defmodule OpenBanking.AccountResourceRequest do
  @moduledoc """

  """
  require Logger

  @application_json "application/json; charset=utf-8"
  @ca_cert_path "./certificates/ob/sandbox/ca.pem"

  @doc """
  Get account resource.
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
      ssl: [
        certfile: cert_path,
        keyfile: key_path,
        cacertfile: @ca_cert_path,
        # secure_renegotiate: true,
        # reuse_sessions: true,
        # verify: :verify_peer,
        verify: :verify_none,
        # fail_if_no_peer_cert: true
        fail_if_no_peer_cert: false
      ]
    )
  end

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
