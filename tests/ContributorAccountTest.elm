module ContributorAccountTest exposing (suite)

import ContributorAccount
import Expect
import Fuzz
import Test exposing (Test)


suite : Test
suite =
    Test.describe "ContributorAccount"
        [ Test.describe "validateRegistrationFields"
            [ Test.test "accepts normalized username and password" <|
                \() ->
                    ContributorAccount.validateRegistrationFields "  Alice  " "password12"
                        |> Expect.equal (Ok { normalizedUsername = "alice", password = "password12" })
            , Test.test "rejects empty username" <|
                \() ->
                    ContributorAccount.validateRegistrationFields "   " "password12"
                        |> Expect.equal (Err ContributorAccount.RegisterUsernameEmpty)
            , Test.test "rejects short username" <|
                \() ->
                    ContributorAccount.validateRegistrationFields "ab" "password12"
                        |> Expect.equal (Err ContributorAccount.RegisterUsernameTooShort)
            , Test.test "rejects invalid first character" <|
                \() ->
                    ContributorAccount.validateRegistrationFields "_abc" "password12"
                        |> Expect.equal (Err ContributorAccount.RegisterUsernameInvalidChars)
            , Test.test "accepts short non-empty password" <|
                \() ->
                    ContributorAccount.validateRegistrationFields "alice" "short"
                        |> Expect.equal (Ok { normalizedUsername = "alice", password = "short" })
            , Test.test "rejects whitespace-only password" <|
                \() ->
                    ContributorAccount.validateRegistrationFields "alice" "   "
                        |> Expect.equal (Err ContributorAccount.RegisterPasswordEmpty)
            , Test.test "trims password in registration result" <|
                \() ->
                    ContributorAccount.validateRegistrationFields "alice" "  x  "
                        |> Expect.equal (Ok { normalizedUsername = "alice", password = "x" })
            , Test.fuzz (Fuzz.intRange 0 99999) "valid default-shaped usernames pass" <|
                \n ->
                    let
                        u : String
                        u =
                            "usr" ++ String.fromInt n
                    in
                    ContributorAccount.validateRegistrationFields u "p"
                        |> Result.map .normalizedUsername
                        |> Expect.equal (Ok (String.toLower u))
            ]
        , Test.describe "verifierFromPassword"
            [ Test.test "verifier matches same password" <|
                \() ->
                    let
                        v : ContributorAccount.Verifier
                        v =
                            ContributorAccount.verifierFromPassword "secret123"
                    in
                    ContributorAccount.verifierMatchesPassword "secret123" v
                        |> Expect.equal True
            , Test.test "verifier rejects different password" <|
                \() ->
                    let
                        v : ContributorAccount.Verifier
                        v =
                            ContributorAccount.verifierFromPassword "secret123"
                    in
                    ContributorAccount.verifierMatchesPassword "other____" v
                        |> Expect.equal False
            ]
        , Test.describe "normalizeUsername"
            [ Test.test "trims and lowercases" <|
                \() ->
                    ContributorAccount.normalizeUsername "  BoB  "
                        |> Expect.equal "bob"
            ]
        , Test.describe "validateLoginFields"
            [ Test.test "accepts non-empty username and password" <|
                \() ->
                    ContributorAccount.validateLoginFields "  Alice  " "x"
                        |> Expect.equal (Ok { normalizedUsername = "alice", password = "x" })
            , Test.test "rejects empty username" <|
                \() ->
                    ContributorAccount.validateLoginFields "   " "secret"
                        |> Expect.equal (Err ContributorAccount.LoginUsernameEmpty)
            , Test.test "rejects empty password" <|
                \() ->
                    ContributorAccount.validateLoginFields "alice" ""
                        |> Expect.equal (Err ContributorAccount.LoginPasswordEmpty)
            , Test.test "rejects whitespace-only password" <|
                \() ->
                    ContributorAccount.validateLoginFields "alice" "   "
                        |> Expect.equal (Err ContributorAccount.LoginPasswordEmpty)
            , Test.test "trims password in login result" <|
                \() ->
                    ContributorAccount.validateLoginFields "alice" "  x  "
                        |> Expect.equal (Ok { normalizedUsername = "alice", password = "x" })
            , Test.fuzz (Fuzz.intRange 0 99999) "accepts usrN-shaped usernames with any non-empty password" <|
                \n ->
                    let
                        u : String
                        u =
                            "usr" ++ String.fromInt n
                    in
                    ContributorAccount.validateLoginFields u "p"
                        |> Expect.equal (Ok { normalizedUsername = String.toLower u, password = "p" })
            ]
        , Test.describe "loginErrorToUserText"
            [ Test.test "maps invalid credentials" <|
                \() ->
                    ContributorAccount.loginErrorToUserText ContributorAccount.LoginInvalidCredentials
                        |> Expect.equal "Invalid username or password."
            ]
        , Test.describe "remapIdForWikiSlug"
            [ Test.test "rewrites ids for the old wiki slug" <|
                \() ->
                    ContributorAccount.newAccountId "Old" "alice"
                        |> ContributorAccount.remapIdForWikiSlug "Old" "New"
                        |> Expect.equal (ContributorAccount.newAccountId "New" "alice")
            , Test.test "leaves other ids unchanged" <|
                \() ->
                    ContributorAccount.newAccountId "Other" "alice"
                        |> ContributorAccount.remapIdForWikiSlug "Old" "New"
                        |> Expect.equal (ContributorAccount.newAccountId "Other" "alice")
            , Test.fuzz (Fuzz.intRange 0 99999) "round username segment for matching prefix" <|
                \n ->
                    let
                        u : String
                        u =
                            "usr" ++ String.fromInt n
                    in
                    ContributorAccount.newAccountId "W" u
                        |> ContributorAccount.remapIdForWikiSlug "W" "Z"
                        |> Expect.equal (ContributorAccount.newAccountId "Z" u)
            ]
        ]
