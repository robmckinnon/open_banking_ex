defmodule OpenBanking.ClientCredentialsGrant do
  @moduledoc """
  For performing HTTP POST calls to token endpoint.
  """

  import Joken
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
end
