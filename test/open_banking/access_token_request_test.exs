defmodule OpenBanking.AccessTokenRequestTest do
  use ExUnit.Case, async: false
  # doctest OpenBanking.AccessTokenRequest
  alias OpenBanking.{AccessTokenRequest, ApiConfig, IdToken}

  import Mock

  describe "AccessTokenRequest.do_request_access_token" do
    setup do
      [
        config: %ApiConfig{
          client_id: "client_id",
          token_endpoint: "token_endpoint",
          signing_key: "signing_key",
          client_secret: "client_secret"
        },
        token_request_payload: %{
          grant_type: "client_credentials",
          scope: "accounts"
        },
        ssl_options: [
          certfile: "./certificates/transport.pem",
          keyfile: "./certificates/transport.key",
          cacertfile: "./certificates/ob/sandbox/ca.pem",
          verify: :verify_none,
          fail_if_no_peer_cert: false
        ],
        mock_post: fn _token_endpoint, _body, _headers, _options ->
          {:ok, "response"}
        end,
        mock_claims: fn client_id: _client_id, token_endpoint: _token_endpoint ->
          {:ok, "claims"}
        end,
        mock_sign: fn _claims, _signing_key ->
          {:ok, "jwt", "signed_claims"}
        end
      ]
    end

    test "with 'client_secret_basic' calls HTTPoison.post with auth header set", context do
      with_mock HTTPoison, post: context[:mock_post] do
        config =
          context[:config]
          |> Map.put(:token_endpoint_auth_method, "client_secret_basic")

        context[:token_request_payload]
        |> AccessTokenRequest.do_request_access_token(config)

        expected_access_token_request = context[:token_request_payload] |> Map.to_list()

        assert_called(
          HTTPoison.post(
            "token_endpoint",
            {:form, expected_access_token_request},
            [
              {"Content-Type", "application/x-www-form-urlencoded"},
              {"authorization", "Basic Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ="}
            ],
            ssl: context[:ssl_options]
          )
        )
      end
    end

    test "with 'private_key_jwt' calls HTTPoison.post with assertion in request payload",
         context do
      with_mock HTTPoison, post: context[:mock_post] do
        with_mock IdToken, sign: context[:mock_sign], claims: context[:mock_claims] do
          config =
            context[:config]
            |> Map.put(:token_endpoint_auth_method, "private_key_jwt")

          context[:token_request_payload]
          |> AccessTokenRequest.do_request_access_token(config)

          expected_access_token_request = [
            client_assertion: "jwt",
            client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            grant_type: "client_credentials",
            scope: "accounts"
          ]

          assert_called(
            HTTPoison.post(
              "token_endpoint",
              {:form, expected_access_token_request},
              [{"Content-Type", "application/x-www-form-urlencoded"}],
              ssl: context[:ssl_options]
            )
          )
        end
      end
    end
  end
end
