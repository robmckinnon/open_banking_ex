defmodule OpenBanking.ClientCredentialsGrant do
  @moduledoc """
  For performing HTTP POST calls to token endpoint for
  Client Credentials Grant.
  https://tools.ietf.org/html/rfc6749#section-4.4
  """

  import OpenBanking.AccessTokenRequest

  @doc """
  Creates client_credentials access token request payload.

  Access Token Request
  https://tools.ietf.org/html/rfc6749#section-4.4.2

  "grant_type - REQUIRED.  Value MUST be set to "client_credentials".
   scope - OPTIONAL.  The scope of the access request."
  """
  def access_token_request_payload(scope) do
    %{
      grant_type: "client_credentials",
      scope: scope
    }
  end

  @doc """
  Client Credentials Grant
  https://tools.ietf.org/html/rfc6749#section-4.4

  "The client can request an access token using only its client
   credentials...

     +---------+                                  +---------------+
     |         |                                  |               |
     |         |>--(A)- Client Authentication --->| Authorization |
     | Client  |                                  |     Server    |
     |         |<--(B)---- Access Token ---------<|               |
     |         |                                  |               |
     +---------+                                  +---------------+

   The Client Credentials Flow includes the following steps:

   (A)  The client authenticates with the authorization server and
        requests an access token from the token endpoint.

   (B)  The authorization server authenticates the client, and if valid,
        issues an access token."

  """
  def request_access_token(
        client_id,
        token_endpoint,
        signing_key,
        token_endpoint_auth_method = "private_key_jwt",
        scope \\ "accounts payments",
        transport_key_file \\ "./certificates/transport.key",
        transport_cert_file \\ "./certificates/transport.pem"
      )
      when is_binary(client_id) and is_binary(token_endpoint) and
             is_binary(token_endpoint_auth_method) and is_binary(scope) do
    scope
    |> access_token_request_payload()
    |> do_request_access_token(
      client_id,
      token_endpoint,
      signing_key,
      token_endpoint_auth_method,
      transport_key_file,
      transport_cert_file
    )
  end
end
