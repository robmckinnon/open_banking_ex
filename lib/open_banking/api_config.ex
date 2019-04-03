defmodule OpenBanking.ApiConfig do
  @moduledoc """
  Holds configuration required to access an ASPSP's Open Banking API
  implementation.
  """
  defstruct auth_server_issuer: "",
            authorization_endpoint: "",
            client_id: "",
            client_secret: "",
            fapi_financial_id: "",
            kid: "",
            permissions: [],
            registered_redirect_url: "http://0.0.0.0/oauth2/callback",
            resource_endpoint: "",
            scope: "accounts payments",
            signing_alg: "",
            signing_key: "",
            token_endpoint: "",
            token_endpoint_auth_method: "client_secret_basic",
            transport_cert_file: "./certificates/transport.pem",
            transport_key_file: "./certificates/transport.key"
end
