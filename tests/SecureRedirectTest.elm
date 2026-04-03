module SecureRedirectTest exposing (suite)

import Expect
import SecureRedirect
import Test exposing (Test)


suite : Test
suite =
    Test.describe "SecureRedirect"
        [ Test.describe "safeContributorReturnPath"
            [ Test.test "accepts wiki home" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "demo" "/w/demo"
                        |> Expect.equal (Just "/w/demo")
            , Test.test "accepts same-wiki path" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "demo" "/w/demo/review"
                        |> Expect.equal (Just "/w/demo/review")
            , Test.test "accepts root" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "demo" "/"
                        |> Expect.equal (Just "/")
            , Test.test "rejects other wiki after path normalization" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "demo" "/w/demo/../../w/other/review"
                        |> Expect.equal Nothing
            , Test.test "normalizes harmless dot segments" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "demo" "/w/demo/submit/../review"
                        |> Expect.equal (Just "/w/demo/review")
            , Test.test "preserves query on canonical path" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "demo" "/w/demo/review?sort=id"
                        |> Expect.equal (Just "/w/demo/review?sort=id")
            , Test.test "rejects protocol-relative" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "demo" "//evil.example/w/demo/review"
                        |> Expect.equal Nothing
            ]
        , Test.describe "safeHostAdminReturnPath"
            [ Test.test "accepts /admin" <|
                \() ->
                    SecureRedirect.safeHostAdminReturnPath "/admin"
                        |> Expect.equal (Just "/admin")
            , Test.test "accepts /admin/wikis" <|
                \() ->
                    SecureRedirect.safeHostAdminReturnPath "/admin/wikis"
                        |> Expect.equal (Just "/admin/wikis")
            , Test.test "rejects path that normalizes outside /admin" <|
                \() ->
                    SecureRedirect.safeHostAdminReturnPath "/admin/../w/demo"
                        |> Expect.equal Nothing
            , Test.test "normalizes inside /admin" <|
                \() ->
                    SecureRedirect.safeHostAdminReturnPath "/admin/foo/../wikis"
                        |> Expect.equal (Just "/admin/wikis")
            ]
        , Test.describe "contributorRedirectFromQuery"
            [ Test.test "parses encoded redirect for same wiki" <|
                \() ->
                    SecureRedirect.contributorRedirectFromQuery "demo" (Just "redirect=%2Fw%2Fdemo%2Freview")
                        |> Expect.equal (Just "/w/demo/review")
            , Test.test "first redirect= wins" <|
                \() ->
                    SecureRedirect.contributorRedirectFromQuery "demo" (Just "redirect=%2Fw%2Fdemo&redirect=%2F")
                        |> Expect.equal (Just "/w/demo")
            , Test.test "rejects traversal in decoded value" <|
                \() ->
                    SecureRedirect.contributorRedirectFromQuery "demo" (Just "redirect=%2Fw%2Fdemo%2F..%2F..%2Fw%2Fother")
                        |> Expect.equal Nothing
            ]
        , Test.describe "hostAdminRedirectFromQuery"
            [ Test.test "parses encoded admin path" <|
                \() ->
                    SecureRedirect.hostAdminRedirectFromQuery (Just "redirect=%2Fadmin%2Fwikis")
                        |> Expect.equal (Just "/admin/wikis")
            ]
        ]
