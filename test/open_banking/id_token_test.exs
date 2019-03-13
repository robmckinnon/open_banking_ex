defmodule OpenBanking.IdTokenTest do
  use ExUnit.Case

  import Mock
  alias OpenBanking.IdToken

  test "generates claims with required fields" do
    with_mock DateTime, utc_now: fn -> "mock" end, to_unix: fn "mock" -> 1_536_353_830 end do
      assert {:ok,
              claims = %{"aud" => aud, "exp" => exp, "iat" => iat, "iss" => iss, "sub" => sub}} =
               IdToken.claims(
                 iss: "iss",
                 sub: "sub",
                 aud: "aud"
               )

      assert "aud" = aud
      assert 1_536_354_430 = exp
      assert 1_536_353_830 = iat
      assert "iss" = iss
      assert "sub" = sub
    end
  end

  test "generates claims with required fields given expiry time in seconds" do
    with_mock DateTime, utc_now: fn -> "mock" end, to_unix: fn "mock" -> 1_536_353_830 end do
      assert {:ok,
              claims = %{"aud" => aud, "exp" => exp, "iat" => iat, "iss" => iss, "sub" => sub}} =
               IdToken.claims(
                 iss: "iss",
                 sub: "sub",
                 aud: "aud",
                 default_exp: 1000
               )

      assert "aud" = aud
      assert 1_536_354_830 = exp
      assert 1_536_353_830 = iat
      assert "iss" = iss
      assert "sub" = sub
    end
  end
end
