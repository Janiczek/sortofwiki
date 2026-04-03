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
                    SecureRedirect.safeContributorReturnPath "Demo" "/w/Demo"
                        |> Expect.equal (Just "/w/Demo")
            , Test.test "accepts same-wiki path" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "Demo" "/w/Demo/review"
                        |> Expect.equal (Just "/w/Demo/review")
            , Test.test "accepts root" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "Demo" "/"
                        |> Expect.equal (Just "/")
            , Test.test "rejects other wiki after path normalization" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "Demo" "/w/Demo/../../w/other/review"
                        |> Expect.equal Nothing
            , Test.test "normalizes harmless dot segments" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "Demo" "/w/Demo/submit/../review"
                        |> Expect.equal (Just "/w/Demo/review")
            , Test.test "preserves query on canonical path" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "Demo" "/w/Demo/review?sort=id"
                        |> Expect.equal (Just "/w/Demo/review?sort=id")
            , Test.test "rejects protocol-relative" <|
                \() ->
                    SecureRedirect.safeContributorReturnPath "Demo" "//evil.example/w/Demo/review"
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
            , Test.test "accepts /admin/backup" <|
                \() ->
                    SecureRedirect.safeHostAdminReturnPath "/admin/backup"
                        |> Expect.equal (Just "/admin/backup")
            , Test.test "rejects path that normalizes outside /admin" <|
                \() ->
                    SecureRedirect.safeHostAdminReturnPath "/admin/../w/Demo"
                        |> Expect.equal Nothing
            , Test.test "normalizes inside /admin" <|
                \() ->
                    SecureRedirect.safeHostAdminReturnPath "/admin/foo/../wikis"
                        |> Expect.equal (Just "/admin/wikis")
            ]
        , Test.describe "contributorRedirectFromQuery"
            [ Test.test "parses encoded redirect for same wiki" <|
                \() ->
                    SecureRedirect.contributorRedirectFromQuery "Demo" (Just "redirect=%2Fw%2FDemo%2Freview")
                        |> Expect.equal (Just "/w/Demo/review")
            , Test.test "first redirect= wins" <|
                \() ->
                    SecureRedirect.contributorRedirectFromQuery "Demo" (Just "redirect=%2Fw%2FDemo&redirect=%2F")
                        |> Expect.equal (Just "/w/Demo")
            , Test.test "rejects traversal in decoded value" <|
                \() ->
                    SecureRedirect.contributorRedirectFromQuery "Demo" (Just "redirect=%2Fw%2FDemo%2F..%2F..%2Fw%2Fother")
                        |> Expect.equal Nothing
            ]
        , Test.describe "hostAdminRedirectFromQuery"
            [ Test.test "parses encoded admin path" <|
                \() ->
                    SecureRedirect.hostAdminRedirectFromQuery (Just "redirect=%2Fadmin%2Fwikis")
                        |> Expect.equal (Just "/admin/wikis")
            ]
        ]
