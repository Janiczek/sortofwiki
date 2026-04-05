module WikiRoleTest exposing (suite)

import Expect
import Fuzzers
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test)
import WikiRole


suite : Test
suite =
    Test.describe "WikiRole"
        [ Test.describe "hasMySubmissionsAccess"
            [ Test.test "true for Contributor" <|
                \() ->
                    WikiRole.hasMySubmissionsAccess (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                        |> Expect.equal True
            , Test.test "false for Trusted" <|
                \() ->
                    WikiRole.hasMySubmissionsAccess WikiRole.TrustedContributor
                        |> Expect.equal False
            , Test.test "false for Admin" <|
                \() ->
                    WikiRole.hasMySubmissionsAccess WikiRole.Admin
                        |> Expect.equal False
            , Test.fuzz Fuzzers.wikiRole "only untrusted tier has My Submissions" <|
                \role ->
                    WikiRole.hasMySubmissionsAccess role
                        |> Expect.equal
                            (case role of
                                WikiRole.UntrustedContributor _ ->
                                    True

                                WikiRole.TrustedContributor ->
                                    False

                                WikiRole.Admin ->
                                    False
                            )
            ]
        , Test.describe "canAccessWikiAdminUsers"
            [ Test.test "false for Contributor" <|
                \() ->
                    WikiRole.canAccessWikiAdminUsers (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                        |> Expect.equal False
            , Test.test "false for Trusted" <|
                \() ->
                    WikiRole.canAccessWikiAdminUsers WikiRole.TrustedContributor
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
                    WikiRole.promoteContributorToTrusted (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                        |> Expect.equal (Just WikiRole.TrustedContributor)
            , Test.test "Trusted unchanged" <|
                \() ->
                    WikiRole.promoteContributorToTrusted WikiRole.TrustedContributor
                        |> Expect.equal Nothing
            , Test.test "Admin unchanged" <|
                \() ->
                    WikiRole.promoteContributorToTrusted WikiRole.Admin
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.wikiRole "only Contributor promotes to Just Trusted" <|
                \role ->
                    WikiRole.promoteContributorToTrusted role
                        |> Expect.equal
                            (if WikiRole.hasMySubmissionsAccess role then
                                Just WikiRole.TrustedContributor

                             else
                                Nothing
                            )
            ]
        , Test.describe "demoteTrustedToContributor"
            [ Test.test "Trusted becomes Contributor" <|
                \() ->
                    WikiRole.demoteTrustedToContributor WikiRole.TrustedContributor
                        |> Expect.equal (Just (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps))
            , Test.test "Contributor unchanged" <|
                \() ->
                    WikiRole.demoteTrustedToContributor (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                        |> Expect.equal Nothing
            , Test.test "Admin unchanged" <|
                \() ->
                    WikiRole.demoteTrustedToContributor WikiRole.Admin
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.wikiRole "only Trusted demotes to Just Contributor" <|
                \role ->
                    WikiRole.demoteTrustedToContributor role
                        |> Expect.equal
                            (if role == WikiRole.TrustedContributor then
                                Just (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)

                             else
                                Nothing
                            )
            ]
        , Test.describe "grantTrustedToAdmin"
            [ Test.test "Trusted becomes Admin" <|
                \() ->
                    WikiRole.grantTrustedToAdmin WikiRole.TrustedContributor
                        |> Expect.equal (Just WikiRole.Admin)
            , Test.test "Contributor unchanged" <|
                \() ->
                    WikiRole.grantTrustedToAdmin (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                        |> Expect.equal Nothing
            , Test.test "Admin unchanged" <|
                \() ->
                    WikiRole.grantTrustedToAdmin WikiRole.Admin
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.wikiRole "only Trusted grants to Just Admin" <|
                \role ->
                    WikiRole.grantTrustedToAdmin role
                        |> Expect.equal
                            (if role == WikiRole.TrustedContributor then
                                Just WikiRole.Admin

                             else
                                Nothing
                            )
            ]
        , Test.describe "revokeAdminToTrusted"
            [ Test.test "Admin becomes Trusted" <|
                \() ->
                    WikiRole.revokeAdminToTrusted WikiRole.Admin
                        |> Expect.equal (Just WikiRole.TrustedContributor)
            , Test.test "Contributor unchanged" <|
                \() ->
                    WikiRole.revokeAdminToTrusted (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                        |> Expect.equal Nothing
            , Test.test "Trusted unchanged" <|
                \() ->
                    WikiRole.revokeAdminToTrusted WikiRole.TrustedContributor
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.wikiRole "only Admin revokes to Just Trusted" <|
                \role ->
                    WikiRole.revokeAdminToTrusted role
                        |> Expect.equal
                            (if role == WikiRole.Admin then
                                Just WikiRole.TrustedContributor

                             else
                                Nothing
                            )
            ]
        , Test.describe "backupTagEncode"
            [ Test.fuzz Fuzzers.wikiRole "backup tag string round-trips through JSON decoder" <|
                \role ->
                    WikiRole.backupTagEncode role
                        |> Encode.string
                        |> Encode.encode 0
                        |> Decode.decodeString WikiRole.backupTagDecoder
                        |> Expect.equal (Ok role)
            ]
        ]
