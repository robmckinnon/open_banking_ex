defmodule OpenBanking do
  @moduledoc """
  For performing calls against Open Banking API.
  """

  defdelegate client_credentials_grant_request_access_token(
                client_id,
                token_endpoint,
                signing_key,
                token_endpoint_auth_method \\ "private_key_jwt",
                scope \\ "accounts payments",
                transport_key_file \\ "./certificates/transport.key",
                transport_cert_file \\ "./certificates/transport.pem"
              ),
              to: OpenBanking.ClientCredentialsGrant,
              as: :request_access_token
end
