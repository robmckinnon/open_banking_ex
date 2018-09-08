defmodule OpenBanking.IdToken do
  @moduledoc """
  For generating ID Token.
  """

  @doc """
  "The primary extension that OpenID Connect makes to OAuth 2.0 to enable
  End-Users to be Authenticated is the ID Token data structure. The ID Token is
  a security token that contains Claims about the Authentication of an End-User
  by an Authorization Server when using a Client, and potentially other
  requested Claims."
  https://openid.net/specs/openid-connect-core-1_0.html#IDToken
  """
  def claims(iss: iss, sub: sub, aud: aud) do
    claims(iss: iss, sub: sub, aud: aud, exp: 600)
  end

  def claims(iss: iss, sub: sub, aud: aud, exp: exp) do
    iat = DateTime.utc_now() |> DateTime.to_unix()

    %{
      # Issuer Identifier for the Issuer of the response:
      iss: iss,
      # Subject Identifier:
      sub: sub,
      # Audience(s) that this ID Token is intended for:
      aud: aud,
      # Expiration time
      exp: iat + exp,
      # Time at which the JWT was issued
      iat: iat
    }
  end
end
