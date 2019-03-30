# open_banking
Elixir helper functions for using Open Banking APIs.

This Elixir API may change before a formal release is made.
It is a work in progress.

## Example usage:

Clone repository, install dependencies, and run Elixir REPL:

```sh
git clone https://github.com/robmckinnon/open_banking.git
cd open_banking

mix deps.get
iex -S mix
```

Here's example code for usage. First define credentials as variables:

```elixir
auth_server_issuer = "https://aspsp.example.com"
authorization_endpoint = "https://aspsp.example.com/auth"
client_id = "abc8bebb-f67e-4485-bfd9-6656d87a681c" # replace with actual client_id
fapi_financial_id = "0012300001041ABCD" # replace with actual fapi_financial_id
kid = "1aBCwxyzYlsVO9lco72IWV2Mqmk" # replace with actual kid
permissions = ["ReadAccountsDetail", "ReadBalances"]
registered_redirect_url = "https://tpp.example.com/oauth2/callback"
resource_endpoint = "https://aspsp.example.com"
scope = "accounts payments"
scope = "openid accounts"
signing_key = "-----BEGIN PRIVATE KEY-----\example\example\example\n-----END PRIVATE KEY-----"
state = ""
token_endpoint = "https://aspsp.example.com/token"
token_endpoint_auth_method = "private_key_jwt"
transport_cert_file = "./certificates/transport.pem"
transport_key_file = "./certificates/transport.key"
```

Here's example code to authorise and call /accounts endpoint:

```elixir
# Client Credentials Grant:
grant_response =
  OpenBanking.ClientCredentialsGrant.request_access_token(
    client_id,
    token_endpoint,
    signing_key,
    client_secret,
    token_endpoint_auth_method,
    scope,
    transport_key_file,
    transport_cert_file
  )

{:ok, access_token} = OpenBanking.AccountAccessConsent.access_token(grant_response)

# Account Access Consent:
consent_id_response =
  OpenBanking.AccountAccessConsent.request_consent_id(
    access_token,
    resource_endpoint,
    fapi_financial_id,
    transport_key_file,
    transport_cert_file,
    permissions
  )

{:ok, consent_id} = OpenBanking.AccountAccessConsent.consent_id(consent_id_response)

# Authorise Consent flow:
consent_url =
  OpenBanking.AuthoriseConsentRedirectionFlow.consent_url(
    authorization_endpoint,
    scope,
    consent_id,
    client_id,
    auth_server_issuer,
    registered_redirect_url,
    kid,
    signing_key,
    state
  )

# Open consent_url in browser, and authorise
System.cmd("open", [consent_url])

# Copy `code` param from redirect back URL, e.g.:
code = "1230aBc8-2c94-4584-b546-f2d269cacabc"

# Authorise Code Grant:
grant_response =
  OpenBanking.AuthorisationCodeGrant.request_access_token(
    client_id,
    token_endpoint,
    signing_key,
    token_endpoint_auth_method,
    registered_redirect_url,
    code
  )

{:ok, resource_access_token} = OpenBanking.AccountAccessConsent.access_token(grant_response)


# Accounts endpoint request:
accounts_endpoint = "#{resource_endpoint}/open-banking/v2.0/accounts"
resource_response =
  OpenBanking.AccountResourceRequest.request_account_resource(
    client_id,
    accounts_endpoint,
    resource_access_token,
    fapi_financial_id
  )
```
