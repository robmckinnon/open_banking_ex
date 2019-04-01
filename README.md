# open_banking_ex

Elixir helper functions for using the [UK Open Banking API](https://www.openbanking.org.uk) standard.

[![Build Status](https://api.travis-ci.org/robmckinnon/open_banking_ex.svg)](https://travis-ci.org/robmckinnon/open_banking_ex)

This Elixir API:

- is not affliated with the Open Banking Implementation Entity (OBIE).
- is a work in progress.
- may change before a formal release is made.

## Open Banking API

To use production Open Banking API implementations from Account Servicing Payment Service Providers (ASPSPs) you must [register and authorise your business with the UK Financial Conduct Authority (FCA)](https://www.fca.org.uk/firms/new-regulated-payment-services-ais-pis).

To test Open Banking APIs without being FCA regulated you can use sandboxes provided by some organisations for that purpose.

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

You can read the "Guide to obtaining sandbox credentials" in the next section below for steps to obtain credentials to access one of the model bank sandboxes.

```elixir
auth_server_issuer = "https://aspsp.example.com"
authorization_endpoint = "https://aspsp.example.com/auth"
client_id = "abc8bebb-f67e-4485-bfd9-6656d87a681c" # replace with actual client_id
client_secret = "c8be8546-ccac-4536-b9b8-4c919451cd44" # set when token_endpoint_auth_method is "client_secret_basic"
fapi_financial_id = "0012300001041ABCD" # replace with actual fapi_financial_id
kid = "1aBCwxyzYlsVO9lco72IWV2Mqmk" # replace with actual kid
permissions = ["ReadAccountsDetail", "ReadBalances"]
registered_redirect_url = "https://tpp.example.com/oauth2/callback"
resource_endpoint = "https://aspsp.example.com"
scope = "accounts payments"
scope = "openid accounts"
signing_key = "-----BEGIN PRIVATE KEY-----\example\example\example\n-----END PRIVATE KEY-----" # set when token_endpoint_auth_method is "private_key_jwt"
state = ""
token_endpoint = "https://aspsp.example.com/token"
token_endpoint_auth_method = "client_secret_basic" # or "private_key_jwt"
transport_cert_file = "./certificates/transport.pem"
transport_key_file = "./certificates/transport.key"
```

### Client credentials grant

Request an `access_token` using registered `token_endpoint_auth_method`.

When `token_endpoint_auth_method` is:

* `client_secret_basic` provide a `client_secret` value, and `nil` for `signing_key`.
* `private_key_jwt` provide a `signing_key`, and `nil` for `client_secret`.

```elixir
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

{:ok, access_token} = OpenBanking.AccessTokenRequest.access_token(grant_response)
```

### Account access consent

Request a `consent_id` for a given list of `permissions`:

```elixir
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
```

### Authorise consent flow

Generate a `consent_url` to send the Payment Service User (PSU) to:

```elixir
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

### Authorise code grant

Request a `resouce_access_token`, using consent `code`:

```elixir
grant_response =
  OpenBanking.AuthorisationCodeGrant.request_access_token(
    client_id,
    token_endpoint,
    signing_key,
    client_secret,
    token_endpoint_auth_method,
    registered_redirect_url,
    code
  )

{:ok, resource_access_token} = OpenBanking.AccessTokenRequest.access_token(grant_response)
```

### Resource API endpoint request

Make an accounts API endpoint request, using `resource_access_token`:

```elixir
accounts_endpoint = "#{resource_endpoint}/open-banking/v2.0/accounts"

resource_response =
  OpenBanking.AccountResourceRequest.request_account_resource(
    client_id,
    accounts_endpoint,
    resource_access_token,
    fapi_financial_id
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
