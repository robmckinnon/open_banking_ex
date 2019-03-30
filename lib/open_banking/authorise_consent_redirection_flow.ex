defmodule OpenBanking.AuthoriseConsentRedirectionFlow do
  @moduledoc """
  For performing authorise consent redirection flow steps.
  """

  # alias Joken.Signer
  alias JsonWebToken.Jwa
  require Logger

  defp claims(consent_id) do
    %{
      userinfo: %{
        openbanking_intent_id: %{
          value: consent_id,
          essential: true
        }
      },
      id_token: %{
        openbanking_intent_id: %{
          value: consent_id,
          essential: true
        },
        acr: %{
          value: "urn:openbanking:psd2:sca",
          essential: true
        }
      }
    }
  end

  @doc """
  Authentication Request

  An Authentication Request is an OAuth 2.0 Authorization Request that requests
  that the End-User be authenticated by the Authorization Server.
  https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest

  OpenID Connect uses the following OAuth 2.0 request parameters with the
  Authorization Code Flow:

  - scope - REQUIRED. OpenID Connect requests MUST contain the openid scope value.
  - response_type - REQUIRED. OAuth 2.0 Response Type value that determines the
    authorization processing flow to be used, including what parameters are
    returned from the endpoints used.
    When using the Authorization Code Flow, this value is code.
  - client_id - REQUIRED. OAuth 2.0 Client Identifier valid at the Authorization Server.
  - redirect_uri - REQUIRED. Redirection URI to which the response will be sent.
    This URI MUST exactly match one of the Redirection URI values for the Client
    pre-registered at the OpenID Provider.
  - state - RECOMMENDED. Opaque value used to maintain state between the request
    and the callback. Typically, Cross-Site Request Forgery (CSRF, XSRF)
    mitigation is done by cryptographically binding the value of this parameter
    with a browser cookie.

  See also, Open Banking Security Profile - Implementer's Draft v1.1.2,
  Hybrid Grant Parameters:
  https://openbanking.atlassian.net/wiki/spaces/DZ/pages/83919096/Open+Banking+Security+Profile+-+Implementer+s+Draft+v1.1.2#OpenBankingSecurityProfile-Implementer'sDraftv1.1.2-HybridGrantParameters
  """
  def authorisation_request(
        scope,
        consent_id,
        client_id,
        auth_server_issuer,
        registered_redirect_url,
        state,
        nonce
      ) do
    %{
      aud: auth_server_issuer,
      iss: client_id,
      response_type: "code",
      client_id: client_id,
      redirect_uri: registered_redirect_url,
      scope: scope,
      state: state,
      nonce: nonce,
      max_age: 86400,
      claims: claims(consent_id)
    }
  end

  @doc """
  JWS sign payload, defaults to RS256 signing alogrithm for now.

  Hybrid Grant Parameters
  Request JWS (Without Base64 encoding)
  https://openbanking.atlassian.net/wiki/spaces/DZ/pages/83919096/Open+Banking+Security+Profile+-+Implementer+s+Draft+v1.1.2#OpenBankingSecurityProfile-Implementer'sDraftv1.1.2-HybridGrantParameters

  The JOSE header for the signature must contain the following fields:

  *alg*
  "The algorithm that will be used for signing the JWS."
  "At the time of publication, PS256 and ES256 are not supported
  and this value must be RS256.
  Once there is sufficient market adoption of PS256, the signing
  algorithm will cut over to PS256 and the use of RS256 will be
  deprecated."

  *kid*
  "This must match the certificate id of the certificate.
  The receiver SHOULD use this value to identify the certificate to
  be used for verifying the JWS."
  """
  def sign(payload, signing_key, kid, alg \\ "RS256") do
    header = %{
      alg: alg,
      kid: kid
    }

    to_sign = signing_input(header, payload)
    "#{to_sign}.#{signature(alg, signing_key, to_sign)}"
  end

  defp signature(algorithm, key, signing_input) do
    key = JsonWebToken.Algorithm.RsaUtil.private_key(key)

    Jwa.sign(algorithm, key, signing_input)
    |> Base.url_encode64(padding: false)
  end

  # defp signature(algorithm, signing_key, signing_input) do
  #   key = %{"pem" => signing_key}
  #   extra_headers = %{"kid" => kid}
  #   signer = Signer.create(alg, key, extra_headers)
  #   {:ok, signed_token_request, claims} = Joken.encode_and_sign(signing_input, signer)
  #
  #   # # Logger.info("Joken.peek_header(token) " <> inspect(Joken.peek_header(signed_token_request)))
  #   # {:ok, signed_token_request, claims}
  #   signed_token_request
  # end

  defp signing_input(header, payload) do
    "#{to_json_base64_encode(header)}.#{to_json_base64_encode(payload)}"
  end

  defp to_json_base64_encode(data) do
    data
    |> Poison.encode()
    |> check_json(data)
    |> Base.url_encode64(padding: false)
  end

  defp check_json({:ok, json}, _data), do: json
  defp check_json({:error, _}, data), do: raise("Failed to encode as JSON: #{inspect(data)}")

  @doc """
  Generates the consent URL for user to perform manual consent flow.
  """
  def consent_url(
        authorization_endpoint,
        scope,
        consent_id,
        client_id,
        auth_server_issuer,
        registered_redirect_url,
        kid,
        signing_key,
        state \\ "",
        nonce \\ nil
      ) do
    request =
      OpenBanking.AuthoriseConsentRedirectionFlow.authorisation_request(
        scope,
        consent_id,
        client_id,
        auth_server_issuer,
        registered_redirect_url,
        state,
        nonce
      )

    signed_token_request =
      OpenBanking.AuthoriseConsentRedirectionFlow.sign(request, signing_key, kid)

    authorization_endpoint <>
      "?" <>
      URI.encode_query(
        redirect_uri: registered_redirect_url,
        state: state,
        client_id: client_id,
        response_type: "code",
        request: signed_token_request,
        scope: scope
      )
  end
end
