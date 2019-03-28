defmodule OpenBanking.ClientCredentialsGrantTest do
  use ExUnit.Case, async: false

  doctest OpenBanking.ClientCredentialsGrant
  alias OpenBanking.{AccessTokenRequest, ClientCredentialsGrant}
  import Mock

  describe "ClientCredentialsGrant.request_access_token/7" do
    setup do
      [
        client_id: "client_id",
        token_endpoint: "token_endpoint",
        signing_key: "signing_key",
        token_endpoint_auth_method: "private_key_jwt",
        scope: "accounts",
        transport_key_file: "./transport.key",
        transport_cert_file: "./transport.pem",
        mock_fn: fn _client_id,
                    _token_endpoint,
                    _signing_key,
                    _token_endpoint_auth_method,
                    _scope,
                    _transport_key_file,
                    _transport_cert_file ->
          ""
        end
      ]
    end

    test "calls do_request_access_token with all parameters", context do
      with_mock AccessTokenRequest, do_request_access_token: context[:mock_fn] do
        ClientCredentialsGrant.request_access_token(
          context[:client_id],
          context[:token_endpoint],
          context[:signing_key],
          context[:token_endpoint_auth_method],
          context[:scope],
          context[:transport_key_file],
          context[:transport_cert_file]
        )

        assert called(
                 AccessTokenRequest.do_request_access_token(
                   %{
                     grant_type: "client_credentials",
                     scope: context[:scope]
                   },
                   context[:client_id],
                   context[:token_endpoint],
                   context[:signing_key],
                   context[:token_endpoint_auth_method],
                   context[:transport_key_file],
                   context[:transport_cert_file]
                 )
               )
      end
    end

    test "calls do_request_access_token with defaulted parameters", context do
      with_mock AccessTokenRequest, do_request_access_token: context[:mock_fn] do
        ClientCredentialsGrant.request_access_token(
          context[:client_id],
          context[:token_endpoint],
          context[:signing_key],
          context[:token_endpoint_auth_method]
        )

        assert called(
                 AccessTokenRequest.do_request_access_token(
                   %{
                     grant_type: "client_credentials",
                     scope: "accounts payments"
                   },
                   context[:client_id],
                   context[:token_endpoint],
                   context[:signing_key],
                   context[:token_endpoint_auth_method],
                   "./certificates/transport.key",
                   "./certificates/transport.pem"
                 )
               )
      end
    end
  end
end
