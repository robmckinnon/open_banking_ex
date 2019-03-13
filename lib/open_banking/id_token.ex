defmodule OpenBanking.IdToken do
  @moduledoc """
  For generating ID Token.
  """

  alias Joken.Config

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
    Config.default_claims(iss: iss, default_exp: default_exp)
    |> Joken.Config.add_claim("aud", fn -> aud end)
    |> Joken.Config.add_claim("sub", fn -> sub end)
    |> Joken.generate_claims()
  end
end
