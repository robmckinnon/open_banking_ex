defmodule OpenBanking.SslConfig do
  @moduledoc """
  For generating SSL configuration.
  """

  require Logger

  @ca_cert_path "./certificates/ob/sandbox/ca.pem"

  @doc """
  Generate SSL configuration for HTTPoison calls.
  """
  def ssl_config(cert_path, key_path) do
    [
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
  end
end
