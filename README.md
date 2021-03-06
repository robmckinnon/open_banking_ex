# open_banking_ex

Elixir helper functions for using the [UK Open Banking API](https://www.openbanking.org.uk) standard.

[![Build Status](https://api.travis-ci.org/robmckinnon/open_banking_ex.svg)](https://travis-ci.org/robmckinnon/open_banking_ex)

## Contents

- [Caveats](#caveats)
- [Open Banking API](#open-banking-api)
- [Local install](#local-install)
- [Example usage](#example-usage)
- [Guide to obtaining sandbox access credentials](#guide-to-obtaining-sandbox-credentials)

## Caveats

Note this `open_banking_ex` Elixir package:

- Is not affliated with the Open Banking Implementation Entity (OBIE).
- Is a work in progress.
- May change before a formal release is made.

## Open Banking API

You can use sandboxes provided by some organisations to test code against the UK Open Banking API standard without being regulated.

To register with and use _production_ Open Banking API implementations from Account Servicing Payment Service Providers (ASPSPs) you must [register and authorise your business with the UK Financial Conduct Authority (FCA)](https://www.fca.org.uk/firms/new-regulated-payment-services-ais-pis).

## Local install

Install latest version of [Elixir](https://elixir-lang.org/install.html) if not already installed on your local machine.

Clone repository, install dependencies, and run Elixir REPL:

```sh
git clone https://github.com/robmckinnon/open_banking_ex.git
cd open_banking_ex

mix deps.get
iex -S mix
```

## Example usage

Below is example usage code.

### Define configuration

First define configuration as variables.

You can read the [guide to obtaining sandbox access credentials](https://github.com/robmckinnon/open_banking_ex#guide-to-obtaining-sandbox-credentials) in the section below. It contains steps to obtain credentials to access one of the model bank sandboxes.

```sh
iex -S mix
```

```elixir
config = %OpenBanking.ApiConfig{
  auth_server_issuer: "https://aspsp.example.com",
  authorization_endpoint: "https://aspsp.example.com/auth",
  client_id: "abc8bebb-f67e-4485-bfd9-6656d87a681c", # replace with actual client_id
  client_secret: "c8be8546-ccac-4536-b9b8-4c919451cd44", # set when token_endpoint_auth_method is "client_secret_basic"
  fapi_financial_id: "0012300001041ABCD", # replace with actual ASPSP fapi_financial_id
  kid: "1aBCwxyzYlsVO9lco72IWV2Mqmk", # replace with actual kid
  permissions: ["ReadAccountsDetail", "ReadBalances"],
  registered_redirect_url: "https://tpp.example.com/oauth2/callback",
  resource_endpoint: "https://aspsp.example.com",
  scope: "accounts payments",
  signing_alg: "RS256", # set when token_endpoint_auth_method is "private_key_jwt"
  signing_key: "-----BEGIN PRIVATE KEY-----\example\example\example\n-----END PRIVATE KEY-----", # set when token_endpoint_auth_method is "private_key_jwt"
  token_endpoint: "https://aspsp.example.com/token",
  token_endpoint_auth_method: "client_secret_basic", # or "private_key_jwt"
  transport_cert_file: "./certificates/transport.pem",
  transport_key_file: "./certificates/transport.key"
}
```

When your `token_endpoint_auth_method` is `client_secret_basic` provide a `client_secret` value, and `nil` for `signing_key`.

When your `token_endpoint_auth_method` is `private_key_jwt` provide a `signing_key`, and `nil` for `client_secret`.


### Accounts API endpoints access example

Here's a sample overview of the flow to access Account API resource endpoints:

```elixir
alias OpenBanking.{ClientCredentialsGrant, AccessTokenRequest, AccountAccessConsent, AuthoriseConsentRedirectionFlow}

with grant_response <-
       ClientCredentialsGrant.request_access_token(config),
     {:ok, access_token} <- AccessTokenRequest.access_token(grant_response),
     response <-
       AccountAccessConsent.request_consent_id(access_token, config),
     {:ok, consent_id} <-
       AccountAccessConsent.consent_id(response),
     consent_url <-
       AuthoriseConsentRedirectionFlow.consent_url(
         consent_id,
         state = "",
         config
       ) do
  System.cmd("open", [consent_url])
end
```

This opens the `consent_url` in browser. You manually authenticate and authorise
consent via the ASPSP's browser interface and any additional Strong Customer
Authentication (SCA) multi-factor authentication steps.

Then copy the `code` param from redirect back URL in browser address bar and
set as `code` variable in `iex` session, e.g.:

```elixir
code = "1230aBc8-2c94-4584-b546-f2d269cacabc"

import Logger
alias OpenBanking.{AuthorisationCodeGrant, AccountResourceRequest}

with grant_response <- AuthorisationCodeGrant.request_access_token(code, config),
     {:ok, access_token} <- AccessTokenRequest.access_token(grant_response) do

  "#{config.resource_endpoint}/open-banking/v2.0/accounts"
  |> AccountResourceRequest.request_account_resource(access_token, config)
  |> inspect()
  |> Logger.info()

  "#{config.resource_endpoint}/open-banking/v2.0/balances"
  |> AccountResourceRequest.request_account_resource(access_token, config)
  |> inspect()
  |> Logger.info()
end
```

You can see the same steps explained in more detail in the following sections.

#### Client credentials grant

You request an `access_token` using the `token_endpoint_auth_method` your client registered with the ASPSP.

```elixir
grant_response =
  OpenBanking.ClientCredentialsGrant.request_access_token(config)

{:ok, access_token} = OpenBanking.AccessTokenRequest.access_token(grant_response)
```

#### Account access consent

Request a `consent_id` for a given list of `permissions` providing the `access_token` you obtained above:

```elixir
consent_id_response =
  OpenBanking.AccountAccessConsent.request_consent_id(
    access_token,
    config
  )

{:ok, consent_id} = OpenBanking.AccountAccessConsent.consent_id(consent_id_response)
```

#### Authorise consent flow

Generate a `consent_url` to send the Payment Service User (PSU) to, providing the `consent_id` you obtained above:

```elixir
consent_url =
  OpenBanking.AuthoriseConsentRedirectionFlow.consent_url(
    consent_id,
    state="",
    config
  )
```

Open `consent_url` in browser, and authorise:

```elixir
System.cmd("open", [consent_url])
```

Copy `code` param from redirect back URL in browser address bar and
set as `code` variable in `iex` session, e.g.:

```elixir
code = "1230aBc8-2c94-4584-b546-f2d269cacabc"
```

#### Authorise code grant

Request a `resouce_access_token`, using the consent `code` you obtained in previous step:

```elixir
grant_response =
  OpenBanking.AuthorisationCodeGrant.request_access_token(
    code,
    config
  )

{:ok, resource_access_token} = OpenBanking.AccessTokenRequest.access_token(grant_response)
```

#### Resource API endpoint request

Make an accounts API endpoint request, using the `resource_access_token` you obtained in previous step:

```elixir
accounts_endpoint = "#{config.resource_endpoint}/open-banking/v2.0/accounts"

resource_response =
  OpenBanking.AccountResourceRequest.request_account_resource(
    accounts_endpoint,
    resource_access_token,
    config
  )
```

## Guide to obtaining sandbox credentials

In this guide you will register with Ozone's model bank implementation. You will:

* Register with Ozone as a Third Party Provider (TPP).
* Generate certificates for transport and signing of requests to Ozone - self signed certs to be used.

### Step 1: Register with Ozone model bank sandbox

Ozone provides mock Account Servicing Payment Service Providers (ASPSP) via an
Open Banking sandbox implementation.

* [Enrol with Ozone](https://ob2018.o3bank.co.uk:444/pub/home).

Follow the enrolment screens:

* Use a Google or LinkedIn as identity provider to login.
* Enter an organisation name.
* Enter a redirect URI, e.g.: `http://0.0.0.0/callback`
* Continue:

On the completion page, click through the tabs on the Ozone page and take a copy of:

* WELL-KNOWN URL
* RESOURCE SERVER BASE URL - set this as `resource_endpoint` value in Elixir
* CLIENT ID - set this as `client_id` value
* CLIENT SECRET - set this as `client_secret`
* Certificate subject e.g. C=GB,O=Ozone Financial Technology Limited,OU=exampleOU,CN=exampleCN
* The sample PSU login names and passwords, for use when PSU authorises consent on Ozone website.

Optionally download:
- Postman Collection
- Postman Environment

### Generate transport and signing certificates

Mutually Authenticated TLS (MA-TLS) is required to communicate with the Ozone sandbox service.

For sandbox testing, Ozone allows you to create your own certificates. Provided that you set the appropriate fields in accordance with the certificate subject fields on the "Certificate" tab. E.g. C=GB,O=Ozone Financial Technology Limited,OU=exampleOU,CN=exampleCN

As an output, you will require the following files to proceed:

* signing.key (private key)
* signing.pem (certificate)
* transport.key
* transport.pem

#### Generate ca.key/ca.pem

First, you create a Certificate Authority (CA) key. Its required to sign the transport and signing certs.

`openssl req -new -x509 -days 3650 -keyout ca.key -out ca.pem -nodes -subj "/C=GB/O=Ozone Financial Technology Limited/OU=exampleOU/CN=exampleCN"`

#### Generate transport certificate

You generate transport certificate as follows, replacing OU and CN with your values from Ozone registration:

`openssl genrsa -out transport.key 2048`

`openssl req -new -sha256 -key transport.key -out transport.csr -subj "/C=GB/O=Ozone Financial Technology Limited/OU=exampleOU/CN=exampleCN"`

`openssl x509 -req -days 3650 -in transport.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out transport.pem`

In Elixir set `transport_cert_file` value to location of `transport.pem`, and
`transport_key_file` value to location of `./certificates/transport.key`.


#### Generate signing certificate

You generate signing certificate as follows, replacing OU and CN with your values from Ozone registration:

`openssl genrsa -out signing.key 2048`

`openssl req -new -sha256 -key signing.key -out signing.csr -subj "/C=GB/O=Ozone Financial Technology Limited/OU=exampleOU/CN=exampleCN"`

`openssl x509 -req -days 3650 -in signing.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out signing.pem`

In Elixir set `signing_key` value to `nil` as `token_endpoint_auth_method` is `client_secret_basic`.

However if you register TPP with `token_endpoint_auth_method` `private_key_jwt` set `signing_key` value to be string contents of `signing.key`.
