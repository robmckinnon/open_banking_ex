defmodule OpenBanking.IdToken do
  @moduledoc """
  For generating ID Token.
  """

  alias Joken.{Config, Signer}

  @doc """
  "The primary extension that OpenID Connect makes to OAuth 2.0 to enable
  End-Users to be Authenticated is the ID Token data structure. The ID Token is
  a security token that contains Claims about the Authentication of an End-User
  by an Authorization Server when using a Client, and potentially other
  requested Claims."
  https://openid.net/specs/openid-connect-core-1_0.html#IDToken

  Examples
    iex> claims(iss: "iss", sub: "sub", aud: "aud")
  """
  def claims(iss: iss, sub: sub, aud: aud) do
    claims(iss: iss, sub: sub, aud: aud, default_exp: 600)
  end

  def claims(iss: iss, sub: sub, aud: aud, default_exp: default_exp) do
    Config.default_claims(iss: iss, aud: aud, default_exp: default_exp)
    |> Config.add_claim("sub", fn -> sub end)
    |> Joken.generate_claims()
  end

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
  def claims(client_id: client_id, token_endpoint: token_endpoint)
      when is_binary(client_id) and is_binary(token_endpoint) do
    claims(iss: client_id, sub: client_id, aud: token_endpoint)
  end

  @doc """
  Signs claims, defaults to RS256 signing alogrithm for now.

  Returns {:ok, jwt, claims}
  """
  def sign(claims, signing_key) do
    signer = Signer.create("RS256", %{"pem" => signing_key})
    Joken.encode_and_sign(claims, signer)
  end
end
