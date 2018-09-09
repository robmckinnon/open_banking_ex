defmodule OpenBanking.ClientCredentialsGrant do
  @moduledoc """
  For performing HTTP POST calls to token endpoint.
  """

  import Joken
  require Logger
  alias OpenBanking.IdToken

  @doc """
  Function to create claims map for POST to token endpoint.

  "The primary extension that OpenID Connect makes to OAuth 2.0 to enable
  End-Users to be Authenticated is the ID Token data structure. The ID Token is
  a security token that contains Claims about the Authentication of an End-User
  by an Authorization Server when using a Client, and potentially other
  requested Claims."
  https://openid.net/specs/openid-connect-core-1_0.html#IDToken

  Financial-grade API: JWT Secured Authorization Response Mode for OAuth 2.0
  JWT-based Response Mode
  https://bitbucket.org/openid/fapi/src/master/Financial_API_JWT_Secured_Authorization_Response_Mode.md?fileviewer=file-view-default#markdown-header-4-jwt-based-response-mode

  """
  def claims(client_id, token_endpoint) when is_binary(client_id) and is_binary(token_endpoint) do
    IdToken.claims(iss: client_id, sub: client_id, aud: token_endpoint)
  end

  @doc """
  Signs claims, defaults to RS256 signing alogrithm for now.

  Returns {:ok, jwt, claims}
  """
  def sign(claims, signing_key) do
    signer = Joken.Signer.create("RS256", %{"pem" => signing_key})
    Joken.encode_and_sign(claims, signer)
  end

  @doc """
  Creates client_credentials access token request payload.
  """
  def access_token_request_payload(scope, jwt) do
    %{
      scope: scope,
      grant_type: "client_credentials",
      client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
      client_assertion: jwt
    }
  end

  @ca_cert_path "./certificates/ob/sandbox/ca.pem"

  @doc """
  Posts access token request to token endpoint.
  """
  def post_access_request(token_endpoint, access_token_request, key_path, cert_path) do
    access_token_request = access_token_request |> Map.to_list()

    HTTPoison.post(
      token_endpoint,
      {:form, access_token_request},
      [{"Content-Type", "application/x-www-form-urlencoded"}],
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

  Access Token Request
  https://tools.ietf.org/html/rfc6749#section-4.4.2

  "grant_type - REQUIRED.  Value MUST be set to "client_credentials".
   scope - OPTIONAL.  The scope of the access request."
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
    with {:ok, claims} <- claims(client_id, token_endpoint),
         {:ok, jwt, claims} <- sign(claims, signing_key),
         request_payload <- access_token_request_payload(scope, jwt) do
      case post_access_request(
             token_endpoint,
             request_payload,
             transport_key_file,
             transport_cert_file
           ) do
        {:ok, response} ->
          response

        {:error, error = %HTTPoison.Error{reason: reason}} ->
          Logger.warn(inspect(error))
          raise inspect(reason)
      end
    else
      error ->
        Logger.warn(inspect(error))
        raise inspect(error)
    end
  end
end
