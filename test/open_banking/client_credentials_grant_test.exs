defmodule OpenBanking.ClientCredentialsGrantTest do
  use ExUnit.Case, async: false

  doctest OpenBanking.ClientCredentialsGrant
  alias OpenBanking.{AccessTokenRequest, ApiConfig, ClientCredentialsGrant}
  import Mock

  describe "ClientCredentialsGrant.request_access_token" do
    setup do
      [
        config: %ApiConfig{
          client_id: "client_id",
          token_endpoint: "token_endpoint",
          signing_key: "signing_key",
          client_secret: "client_secret",
          token_endpoint_auth_method: "private_key_jwt",
          scope: "accounts",
          transport_key_file: "./transport.key",
          transport_cert_file: "./transport.pem"
        },
        mock_fn: fn _request_payload, _config ->
          ""
        end
      ]
    end

    test "calls do_request_access_token with all parameters", context do
      with_mock AccessTokenRequest, do_request_access_token: context[:mock_fn] do
        ClientCredentialsGrant.request_access_token(context[:config])

        request_payload = %{
          grant_type: "client_credentials",
          scope: context[:config].scope
        }

        assert called(
                 AccessTokenRequest.do_request_access_token(
                   request_payload,
                   context[:config]
                 )
               )
      end
    end
  end
end
