module WikiUserTest exposing (suite)

import ContributorAccount
import Expect
import Test exposing (Test)
import WikiUser


suite : Test
suite =
    Test.describe "WikiUser"
        [ Test.describe "contributorIdForWiki"
            [ Test.test "Nothing when session missing" <|
                \() ->
                    WikiUser.contributorIdForWiki "k" "demo" WikiUser.emptySessions
                        |> Expect.equal Nothing
            , Test.test "Just id when wiki matches binding" <|
                \() ->
                    let
                        acc : ContributorAccount.Id
                        acc =
                            ContributorAccount.newAccountId "demo" "alice"

                        sessions : WikiUser.SessionTable
                        sessions =
                            WikiUser.bindContributor "sess" "demo" acc WikiUser.emptySessions
                    in
                    WikiUser.contributorIdForWiki "sess" "demo" sessions
                        |> Expect.equal (Just acc)
            , Test.test "Nothing when wiki differs from binding" <|
                \() ->
                    let
                        acc : ContributorAccount.Id
                        acc =
                            ContributorAccount.newAccountId "demo" "alice"

                        sessions : WikiUser.SessionTable
                        sessions =
                            WikiUser.bindContributor "sess" "demo" acc WikiUser.emptySessions
                    in
                    WikiUser.contributorIdForWiki "sess" "other" sessions
                        |> Expect.equal Nothing
            ]
        , Test.describe "dropBindingsForWiki"
            [ Test.test "removes sessions for that wiki only" <|
                \() ->
                    let
                        acc : ContributorAccount.Id
                        acc =
                            ContributorAccount.newAccountId "demo" "alice"

                        sessions : WikiUser.SessionTable
                        sessions =
                            WikiUser.emptySessions
                                |> WikiUser.bindContributor "s1" "demo" acc
                                |> WikiUser.bindContributor "s2" "other" acc
                    in
                    WikiUser.dropBindingsForWiki "demo" sessions
                        |> Expect.equal (WikiUser.bindContributor "s2" "other" acc WikiUser.emptySessions)
            ]
        ]
