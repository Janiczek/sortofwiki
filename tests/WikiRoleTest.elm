module WikiRoleTest exposing (suite)

import Expect
import Fuzzers
import Test exposing (Test)
import WikiRole


suite : Test
suite =
    Test.describe "WikiRole"
        [ Test.describe "canAccessWikiAdminUsers"
            [ Test.test "false for Contributor" <|
                \() ->
                    WikiRole.canAccessWikiAdminUsers WikiRole.Contributor
                        |> Expect.equal False
            , Test.test "false for Trusted" <|
                \() ->
                    WikiRole.canAccessWikiAdminUsers WikiRole.Trusted
                        |> Expect.equal False
            , Test.test "true for Admin" <|
                \() ->
                    WikiRole.canAccessWikiAdminUsers WikiRole.Admin
                        |> Expect.equal True
            , Test.fuzz Fuzzers.wikiRole "only Admin may access admin users UI" <|
                \role ->
                    WikiRole.canAccessWikiAdminUsers role
                        |> Expect.equal (role == WikiRole.Admin)
            ]
        , Test.describe "promoteContributorToTrusted"
            [ Test.test "Contributor becomes Trusted" <|
                \() ->
                    WikiRole.promoteContributorToTrusted WikiRole.Contributor
                        |> Expect.equal (Just WikiRole.Trusted)
            , Test.test "Trusted unchanged" <|
                \() ->
                    WikiRole.promoteContributorToTrusted WikiRole.Trusted
                        |> Expect.equal Nothing
            , Test.test "Admin unchanged" <|
                \() ->
                    WikiRole.promoteContributorToTrusted WikiRole.Admin
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.wikiRole "only Contributor promotes to Just Trusted" <|
                \role ->
                    WikiRole.promoteContributorToTrusted role
                        |> Expect.equal
                            (if role == WikiRole.Contributor then
                                Just WikiRole.Trusted

                             else
                                Nothing
                            )
            ]
        , Test.describe "demoteTrustedToContributor"
            [ Test.test "Trusted becomes Contributor" <|
                \() ->
                    WikiRole.demoteTrustedToContributor WikiRole.Trusted
                        |> Expect.equal (Just WikiRole.Contributor)
            , Test.test "Contributor unchanged" <|
                \() ->
                    WikiRole.demoteTrustedToContributor WikiRole.Contributor
                        |> Expect.equal Nothing
            , Test.test "Admin unchanged" <|
                \() ->
                    WikiRole.demoteTrustedToContributor WikiRole.Admin
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.wikiRole "only Trusted demotes to Just Contributor" <|
                \role ->
                    WikiRole.demoteTrustedToContributor role
                        |> Expect.equal
                            (if role == WikiRole.Trusted then
                                Just WikiRole.Contributor

                             else
                                Nothing
                            )
            ]
        , Test.describe "grantTrustedToAdmin"
            [ Test.test "Trusted becomes Admin" <|
                \() ->
                    WikiRole.grantTrustedToAdmin WikiRole.Trusted
                        |> Expect.equal (Just WikiRole.Admin)
            , Test.test "Contributor unchanged" <|
                \() ->
                    WikiRole.grantTrustedToAdmin WikiRole.Contributor
                        |> Expect.equal Nothing
            , Test.test "Admin unchanged" <|
                \() ->
                    WikiRole.grantTrustedToAdmin WikiRole.Admin
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.wikiRole "only Trusted grants to Just Admin" <|
                \role ->
                    WikiRole.grantTrustedToAdmin role
                        |> Expect.equal
                            (if role == WikiRole.Trusted then
                                Just WikiRole.Admin

                             else
                                Nothing
                            )
            ]
        , Test.describe "revokeAdminToTrusted"
            [ Test.test "Admin becomes Trusted" <|
                \() ->
                    WikiRole.revokeAdminToTrusted WikiRole.Admin
                        |> Expect.equal (Just WikiRole.Trusted)
            , Test.test "Contributor unchanged" <|
                \() ->
                    WikiRole.revokeAdminToTrusted WikiRole.Contributor
                        |> Expect.equal Nothing
            , Test.test "Trusted unchanged" <|
                \() ->
                    WikiRole.revokeAdminToTrusted WikiRole.Trusted
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.wikiRole "only Admin revokes to Just Trusted" <|
                \role ->
                    WikiRole.revokeAdminToTrusted role
                        |> Expect.equal
                            (if role == WikiRole.Admin then
                                Just WikiRole.Trusted

                             else
                                Nothing
                            )
            ]
        ]
