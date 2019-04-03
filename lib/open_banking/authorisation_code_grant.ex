defmodule OpenBanking.AuthorisationCodeGrant do
  @moduledoc """
  For performing HTTP POST calls to token endpoint for
  Authorization Code Grant.
  https://tools.ietf.org/html/rfc6749#section-4.1
  """

  alias OpenBanking.ApiConfig
  import OpenBanking.AccessTokenRequest

  @doc """
  Access Token Request
  https://tools.ietf.org/html/rfc6749#section-4.1.3

  grant_type - REQUIRED.  Value MUST be set to "authorization_code".

  code - REQUIRED.  The authorization code received from the
        authorization server.

  redirect_uri - REQUIRED, if the "redirect_uri" parameter was included in the
        authorization request, and their values MUST be identical.

  client_id - REQUIRED, if the client is not authenticating with the
        authorization server.
  """
  def access_token_request_payload(authorisation_code, client_id, redirect_uri) do
    %{
      grant_type: "authorization_code",
      redirect_uri: redirect_uri,
      code: authorisation_code,
      client_id: client_id
    }
  end

  @doc """
  Authorization Code Grant
  https://tools.ietf.org/html/rfc6749#section-4.1

  Headless Flow (deviates from rfc6749):


  +----|-----+          Client Identifier      +---------------+
  |         -+----(A)-- & Redirection URI ---->|               |
  |          |                                 | Authorization |
  |  app    -+                                 |     Server    |
  |          |                                 |               |
  |         -+----(B)-- Authorization Code ---<|               |
  +-|----|---+                                 +---------------+
    |    |                                         ^      v
   (A)  (B)                                        |      |
    |    |                                         |      |
    ^    v                                         |      |
  +---------+                                      |      |
  |         |>---(C)-- Authorization Code ---------'      |
  |         |          & Redirection URI                  |
  |         |                                             |
  |         |<---(D)----- Access Token -------------------'
  +---------+       (w/ Optional Refresh Token)
  """
  def request_access_token(
        authorisation_code,
        config = %ApiConfig{}
      )
      when is_binary(authorisation_code) do
    authorisation_code
    |> access_token_request_payload(config.client_id, config.registered_redirect_url)
    |> do_request_access_token(config)
  end
end
