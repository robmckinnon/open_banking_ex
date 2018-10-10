defmodule OpenBanking.AccessTokenRequest do
  @moduledoc """
  For performing HTTP POST calls to token endpoint.
  """

  require Logger
  alias OpenBanking.IdToken

  @ca_cert_path "./certificates/ob/sandbox/ca.pem"

  def do_request_access_token(
        request_payload,
        client_id,
        token_endpoint,
        signing_key,
        token_endpoint_auth_method = "private_key_jwt",
        transport_key_file \\ "./certificates/transport.key",
        transport_cert_file \\ "./certificates/transport.pem"
      )
      when is_binary(client_id) and is_binary(token_endpoint) and
             is_binary(token_endpoint_auth_method) do
    with {:ok, claims} <- IdToken.claims(client_id: client_id, token_endpoint: token_endpoint),
         {:ok, jwt, _claims} <- IdToken.sign(claims, signing_key) do
      request_payload =
        request_payload
        |> Map.merge(%{
          client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
          client_assertion: jwt
        })

      token_endpoint
      |> post_access_request(
        request_payload,
        transport_key_file,
        transport_cert_file
      )
      |> handle_response
    else
      error ->
        Logger.warn(inspect(error))
        raise inspect(error)
    end
  end

  defp handle_response({:ok, response}), do: response

  defp handle_response({:error, error = %HTTPoison.Error{reason: reason}}) do
    Logger.warn(inspect(error))
    raise inspect(reason)
  end

  @doc """
  Posts access token request to token endpoint.
  """
  def post_access_request(token_endpoint, access_token_request, key_path, cert_path) do
    access_token_request = access_token_request |> Map.to_list()
    Logger.info(inspect(access_token_request))

    HTTPoison.post(
      token_endpoint,
      {:form, access_token_request},
      [{"Content-Type", "application/x-www-form-urlencoded"}],
      ssl: [
        certfile: cert_path,
        keyfile: key_path,
        cacertfile: @ca_cert_path,
        # secure_renegotiate: true,
        # reuse_sessions: true,
        # verify: :verify_peer,
        verify: :verify_none,
        # fail_if_no_peer_cert: true
        fail_if_no_peer_cert: false
      ]
    )
  end

  @doc """
  Returns access_token from response body.

  Examples:

  iex> response = %HTTPoison.Response{
  iex>   body: "{\\"access_token\\":\\"59855fa2-a231-4661-a751-875e6a378eed\\",\\"token_type\\":\\"Bearer\\",\\"expires_in\\":3600}",
  iex>   status_code: 200
  iex> }
  iex> OpenBanking.ClientCredentialsGrant.access_token(response)
  {:ok, "59855fa2-a231-4661-a751-875e6a378eed"}

  iex> response = %HTTPoison.Response{
  iex>   body: "{\\"token_type\\":\\"Bearer\\",\\"expires_in\\":3600}",
  iex>   status_code: 200
  iex> }
  iex> OpenBanking.ClientCredentialsGrant.access_token(response)
  {:error, "No access_token present in: {\\"token_type\\":\\"Bearer\\",\\"expires_in\\":3600}"}

  iex> response = %HTTPoison.Response{
  iex>   body: "invalid-json",
  iex>   status_code: 200
  iex> }
  iex> OpenBanking.ClientCredentialsGrant.access_token(response)
  {:error, "No access_token present due to invalid JSON: invalid-json"}
  """
  def access_token(%{body: body, status_code: 200}) when is_binary(body) do
    case Poison.decode(body) do
      {:ok, parsed} ->
        case parsed do
          %{"access_token" => access_token} -> {:ok, access_token}
          _ -> {:error, "No access_token present in: #{body}"}
        end

      {:error, _reason} ->
        {:error, "No access_token present due to invalid JSON: #{body}"}
    end
  end
end
