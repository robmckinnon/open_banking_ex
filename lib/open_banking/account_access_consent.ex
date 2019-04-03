defmodule OpenBanking.AccountAccessConsent do
  @moduledoc """
  For performing HTTP POST calls to token endpoint.
  """

  alias OpenBanking.{ApiConfig, SslConfig}
  require Logger

  defp headers(access_token, fapi_financial_id) do
    [
      Authorization: "Bearer #{access_token}",
      "x-fapi-financial-id": fapi_financial_id,
      # x-fapi-customer-last-logged-time: Sun, 10 Sep 2017 19:43:31 UTC
      # x-fapi-customer-ip-address: 104.25.212.99
      # x-fapi-interaction-id: 93bac548-d2de-4546-b106-880a5018460d
      "Content-Type": "application/json",
      Accept: "application/json"
    ]
  end

  @all_permissions [
    "ReadAccountsDetail",
    "ReadBalances",
    "ReadBeneficiariesDetail",
    "ReadDirectDebits",
    "ReadProducts",
    "ReadStandingOrdersDetail",
    "ReadTransactionsCredits",
    "ReadTransactionsDebits",
    "ReadTransactionsDetail",
    "ReadOffers",
    "ReadPAN",
    "ReadParty",
    "ReadPartyPSU",
    "ReadScheduledPaymentsDetail",
    "ReadStatementsDetail"
  ]

  defp request_payload(permissions) do
    %{
      Data: %{
        Permissions: permissions
        # ExpirationDateTime: "2017-05-02T00:00:00+00:00",
        # TransactionFromDateTime: "2017-05-03T00:00:00+00:00",
        # TransactionToDateTime: "2017-12-03T00:00:00+00:00"
      },
      Risk: %{}
    }
    |> Poison.encode!()
  end

  @doc """
  Account access consent request, to obtain
  ConsentId/AccountRequestId.
  """
  def request_consent_id(
        access_token,
        config = %ApiConfig{}
      )
      when is_binary(access_token) do
    with headers <- headers(access_token, config.fapi_financial_id),
         request_payload <- request_payload(config.permissions),
         ssl_config <- SslConfig.ssl_config(config.transport_cert_file, config.transport_key_file) do
      case HTTPoison.post(
             "#{config.resource_endpoint}/open-banking/v2.0/account-requests",
             request_payload,
             headers,
             ssl: ssl_config
           ) do
        {:ok, response} ->
          response

        {:error, error = %HTTPoison.Error{reason: reason}} ->
          Logger.warn(inspect(error))
          raise inspect(reason)
      end
    end
  end

  @doc """
  Returns ConsentId from response body.

  Examples:

  iex> response = %HTTPoison.Response{
  iex>   body: "{\\"Data\\":{\\"AccountRequestId\\":\\"ae49844c-5912-43bc-bac8-2bd8313ce4e0\\",\\"Permissions\\":[\\"ReadAccountsDetail\\"],\\"CreationDateTime\\":\\"2018-09-22T13:24:31.010Z\\",\\"Status\\":\\"AwaitingAuthorisation\\",\\"StatusUpdateDateTime\\":\\"2018-09-22T13:24:31.010Z\\"},\\"Links\\":{},\\"Meta\\":{},\\"Risk\\":{}}",
  iex>   status_code: 201
  iex> }
  iex> OpenBanking.AccountAccessConsent.consent_id(response)
  {:ok, "ae49844c-5912-43bc-bac8-2bd8313ce4e0"}

  iex> response = %HTTPoison.Response{
  iex>   body: "{\\"Data\\":{\\"ConsentId\\":\\"be49844c-5912-43bc-bac8-2bd8313ce4e0\\",\\"Permissions\\":[\\"ReadAccountsDetail\\"],\\"CreationDateTime\\":\\"2018-09-22T13:24:31.010Z\\",\\"Status\\":\\"AwaitingAuthorisation\\",\\"StatusUpdateDateTime\\":\\"2018-09-22T13:24:31.010Z\\"},\\"Links\\":{},\\"Meta\\":{},\\"Risk\\":{}}",
  iex>   status_code: 201
  iex> }
  iex> OpenBanking.AccountAccessConsent.consent_id(response)
  {:ok, "be49844c-5912-43bc-bac8-2bd8313ce4e0"}

  iex> response = %HTTPoison.Response{
  iex>   body: "{\\"Data\\":{}}",
  iex>   status_code: 201
  iex> }
  iex> OpenBanking.AccountAccessConsent.consent_id(response)
  {:error, "No ConsentId/AccountRequestId present in: {\\"Data\\":{}}"}

  iex> response = %HTTPoison.Response{
  iex>   body: "invalid-json",
  iex>   status_code: 201
  iex> }
  iex> OpenBanking.AccountAccessConsent.consent_id(response)
  {:error, "No ConsentId/AccountRequestId present due to invalid JSON: invalid-json"}
  """
  def consent_id(%{body: body, status_code: 201}) when is_binary(body) do
    case Poison.decode(body) do
      {:ok, parsed} ->
        case parsed do
          %{"Data" => %{"AccountRequestId" => consent_id}} -> {:ok, consent_id}
          %{"Data" => %{"ConsentId" => consent_id}} -> {:ok, consent_id}
          _ -> {:error, "No ConsentId/AccountRequestId present in: #{body}"}
        end

      {:error, _reason} ->
        {:error, "No ConsentId/AccountRequestId present due to invalid JSON: #{body}"}
    end
  end
end
