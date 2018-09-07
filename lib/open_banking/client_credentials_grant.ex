defmodule OpenBanking.ClientCredentialsGrant do
  @moduledoc """
  For performing HTTP POST calls to token endpoint.
  """

  import Joken

  @doc """
  Function to create claims map for POST to token endpoint.

  "The primary extension that OpenID Connect makes to OAuth 2.0 to enable
  End-Users to be Authenticated is the ID Token data structure. The ID Token is
  a security token that contains Claims about the Authentication of an End-User
  by an Authorization Server when using a Client, and potentially other
  requested Claims."
  https://openid.net/specs/openid-connect-core-1_0.html#IDToken

  ## Examples

      iex> OpenBanking.ClientCredentialsGrant.claims("example_client_id","http://example.com/token")
      %{
        iss: "example_client_id",
        sub: "example_client_id",
        aud: "http://example.com/token"
      }
  """
  def claims(client_id, token_endpoint) when is_binary(client_id) and is_binary(token_endpoint) do
    %{
      # Issuer Identifier for the Issuer of the response:
      iss: client_id,
      # Subject Identifier:
      sub: client_id,
      # Audience(s) that this ID Token is intended for:
      aud: token_endpoint
    }
  end
end
