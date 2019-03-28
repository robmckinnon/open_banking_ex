defmodule OpenBanking.ClientCredentialsGrantTest do
  use ExUnit.Case, async: false

  doctest OpenBanking.ClientCredentialsGrant
  alias OpenBanking.{AccessTokenRequest, ClientCredentialsGrant}
  import Mock

  test "request_access_token calls do_request_access_token with parameters" do
    with_mock AccessTokenRequest,
      do_request_access_token: fn _client_id,
                                  _token_endpoint,
                                  _signing_key,
                                  _token_endpoint_auth_method,
                                  _scope,
                                  _transport_key_file,
                                  _transport_cert_file ->
        ""
      end do
      client_id = "client_id"
      token_endpoint = "token_endpoint"
      signing_key = "signing_key"
      token_endpoint_auth_method = "private_key_jwt"
      scope = "accounts"
      transport_key_file = "./transport.key"
      transport_cert_file = "./transport.pem"

      ClientCredentialsGrant.request_access_token(
        client_id,
        token_endpoint,
        signing_key,
        token_endpoint_auth_method,
        scope,
        transport_key_file,
        transport_cert_file
      )

      assert called(
               AccessTokenRequest.do_request_access_token(
                 %{
                   grant_type: "client_credentials",
                   scope: scope
                 },
                 client_id,
                 token_endpoint,
                 signing_key,
                 token_endpoint_auth_method,
                 transport_key_file,
                 transport_cert_file
               )
             )
    end
  end

  test "request_access_token calls do_request_access_token with defaulted parameters" do
    with_mock AccessTokenRequest,
      do_request_access_token: fn _client_id,
                                  _token_endpoint,
                                  _signing_key,
                                  _token_endpoint_auth_method,
                                  _scope,
                                  _transport_key_file,
                                  _transport_cert_file ->
        ""
      end do
      client_id = "client_id"
      token_endpoint = "token_endpoint"
      signing_key = "signing_key"
      token_endpoint_auth_method = "private_key_jwt"

      ClientCredentialsGrant.request_access_token(
        client_id,
        token_endpoint,
        signing_key,
        token_endpoint_auth_method
      )

      assert called(
               AccessTokenRequest.do_request_access_token(
                 %{
                   grant_type: "client_credentials",
                   scope: "accounts payments"
                 },
                 client_id,
                 token_endpoint,
                 signing_key,
                 token_endpoint_auth_method,
                 "./certificates/transport.key",
                 "./certificates/transport.pem"
               )
             )
    end
  end
end
