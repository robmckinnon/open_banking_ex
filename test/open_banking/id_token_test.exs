defmodule OpenBanking.IdTokenTest do
  use ExUnit.Case

  import Mock
  alias OpenBanking.IdToken

  test "generates claims with required fields" do
    with_mock DateTime, utc_now: fn -> "mock" end, to_unix: fn "mock" -> 1_536_353_830 end do
      assert %{
               aud: "aud",
               exp: 1_536_354_430,
               iat: 1_536_353_830,
               iss: "iss",
               sub: "sub"
             } =
               IdToken.claims(
                 iss: "iss",
                 sub: "sub",
                 aud: "aud"
               )
    end
  end

  test "generates claims with required fields given expiry time in seconds" do
    with_mock DateTime, utc_now: fn -> "mock" end, to_unix: fn "mock" -> 1_536_353_830 end do
      assert %{
               aud: "aud",
               exp: 1_536_354_830,
               iat: 1_536_353_830,
               iss: "iss",
               sub: "sub"
             } =
               IdToken.claims(
                 iss: "iss",
                 sub: "sub",
                 aud: "aud",
                 exp: 1000
               )
    end
  end
end
