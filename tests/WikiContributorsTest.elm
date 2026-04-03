module WikiContributorsTest exposing (suite)

import ContributorAccount
import Dict
import Expect
import Fuzz
import Test exposing (Test)
import Wiki
import WikiAdminUsers
import WikiContributors
import WikiRole


demoWiki : Wiki.Wiki
demoWiki =
    Wiki.wikiWithPages "Demo" "Demo" Dict.empty


demoWikiInactive : Wiki.Wiki
demoWikiInactive =
    { demoWiki | active = False }


wikis : Dict.Dict Wiki.Slug Wiki.Wiki
wikis =
    Dict.singleton "Demo" demoWiki


wikisInactive : Dict.Dict Wiki.Slug Wiki.Wiki
wikisInactive =
    Dict.singleton "Demo" demoWikiInactive


suite : Test
suite =
    Test.describe "WikiContributors"
        [ Test.describe "attemptRegister"
            [ Test.test "registers first account" <|
                \() ->
                    WikiContributors.attemptRegister "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Result.map (Tuple.mapFirst (always ()))
                        |> Expect.equal (Ok ( (), ContributorAccount.newAccountId "Demo" "alice" ))
            , Test.test "rejects unknown wiki" <|
                \() ->
                    WikiContributors.attemptRegister "missing" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.RegisterWikiNotFound)
            , Test.test "rejects inactive wiki" <|
                \() ->
                    WikiContributors.attemptRegister "Demo" "alice" "password12" wikisInactive WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.RegisterWikiInactive)
            , Test.test "rejects duplicate username" <|
                \() ->
                    case WikiContributors.attemptRegister "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            WikiContributors.attemptRegister "Demo" "Alice" "password12" wikis reg
                                |> Expect.equal (Err ContributorAccount.RegisterUsernameTaken)

                        Err _ ->
                            Expect.fail "expected first register to succeed"
            ]
        , Test.describe "attemptLogin"
            [ Test.test "logs in with correct password" <|
                \() ->
                    case WikiContributors.attemptRegister "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            WikiContributors.attemptLogin "Demo" "Alice" "password12" wikis reg
                                |> Expect.equal (Ok (ContributorAccount.newAccountId "Demo" "alice"))

                        Err _ ->
                            Expect.fail "expected register to succeed"
            , Test.test "rejects unknown wiki" <|
                \() ->
                    WikiContributors.attemptLogin "missing" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.LoginWikiNotFound)
            , Test.test "rejects inactive wiki" <|
                \() ->
                    WikiContributors.attemptLogin "Demo" "alice" "password12" wikisInactive WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.LoginWikiInactive)
            , Test.test "rejects unknown username" <|
                \() ->
                    WikiContributors.attemptLogin "Demo" "nobody" "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.LoginInvalidCredentials)
            , Test.test "rejects wrong password" <|
                \() ->
                    case WikiContributors.attemptRegister "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            WikiContributors.attemptLogin "Demo" "alice" "wrongpass_" wikis reg
                                |> Expect.equal (Err ContributorAccount.LoginInvalidCredentials)

                        Err _ ->
                            Expect.fail "expected register to succeed"
            , Test.test "rejects empty username" <|
                \() ->
                    WikiContributors.attemptLogin "Demo" "   " "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.LoginUsernameEmpty)
            , Test.fuzz (Fuzz.intRange 0 99999) "login after register with same credentials" <|
                \n ->
                    let
                        username : String
                        username =
                            "usr" ++ String.fromInt n

                        password : String
                        password =
                            "password12"
                    in
                    case WikiContributors.attemptRegister "Demo" username password wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            let
                                expectedId : ContributorAccount.Id
                                expectedId =
                                    ContributorAccount.newAccountId "Demo" (String.toLower username)
                            in
                            WikiContributors.attemptLogin "Demo" username password wikis reg
                                |> Expect.equal (Ok expectedId)

                        Err _ ->
                            Expect.fail "expected register to succeed"
            ]
        , Test.describe "roleForAccount"
            [ Test.test "contributor role after register" <|
                \() ->
                    case WikiContributors.attemptRegister "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, accountId ) ->
                            WikiContributors.roleForAccount "Demo" accountId reg
                                |> Expect.equal (Just WikiRole.UntrustedContributor)

                        Err _ ->
                            Expect.fail "expected register to succeed"
            , Test.test "trusted role after trusted seed" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.roleForAccount "Demo" (ContributorAccount.newAccountId "Demo" "trusty") reg
                                |> Expect.equal (Just WikiRole.TrustedContributor)

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "admin role after admin seed" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.roleForAccount "Demo" (ContributorAccount.newAccountId "Demo" "adminuser") reg
                                |> Expect.equal (Just WikiRole.Admin)

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "Nothing for unknown account" <|
                \() ->
                    WikiContributors.roleForAccount "Demo" (ContributorAccount.newAccountId "Demo" "nobody") WikiContributors.emptyRegistry
                        |> Expect.equal Nothing
            ]
        , Test.describe "seedContributorAtWiki"
            [ Test.test "inserts same as attemptRegister for empty registry" <|
                \() ->
                    WikiContributors.seedContributorAtWiki "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Result.map
                            (\reg ->
                                WikiContributors.attemptLogin "Demo" "alice" "password12" wikis reg
                            )
                        |> Expect.equal (Ok (Ok (ContributorAccount.newAccountId "Demo" "alice")))
            , Test.test "rejects unknown wiki" <|
                \() ->
                    WikiContributors.seedContributorAtWiki "missing" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.RegisterWikiNotFound)
            , Test.test "rejects duplicate username" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.seedContributorAtWiki "Demo" "Alice" "otherpass12" wikis reg
                                |> Expect.equal (Err ContributorAccount.RegisterUsernameTaken)

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            ]
        , Test.describe "isTrustedForWiki"
            [ Test.test "false for freshly registered contributor" <|
                \() ->
                    case WikiContributors.attemptRegister "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, accountId ) ->
                            WikiContributors.isTrustedForWiki "Demo" accountId reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected register to succeed"
            , Test.test "true for seeded trusted contributor" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" "trusty") reg
                                |> Expect.equal True

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "true for seeded admin contributor" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" "adminuser") reg
                                |> Expect.equal True

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "false when account id does not match" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" "other") reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "false for trusted user checked on different wiki" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "ElmTips" (ContributorAccount.newAccountId "Demo" "trusty") reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.fuzz (Fuzz.intRange 0 99999) "seeded standard user is never trusted" <|
                \n ->
                    let
                        username : String
                        username =
                            "fuzzstd" ++ String.fromInt n
                    in
                    case WikiContributors.seedContributorAtWiki "Demo" username "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" username) reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            ]
        , Test.describe "isAdminForWiki"
            [ Test.test "true for seeded admin" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isAdminForWiki "Demo" (ContributorAccount.newAccountId "Demo" "adminuser") reg
                                |> Expect.equal True

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "false for seeded trusted" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isAdminForWiki "Demo" (ContributorAccount.newAccountId "Demo" "trusty") reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            ]
        , Test.describe "displayUsernameForAccount"
            [ Test.test "Nothing for unknown wiki" <|
                \() ->
                    WikiContributors.displayUsernameForAccount "missing" (ContributorAccount.newAccountId "Demo" "alice") WikiContributors.emptyRegistry
                        |> Expect.equal Nothing
            , Test.test "Nothing when account not in wiki" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.displayUsernameForAccount "Demo" (ContributorAccount.newAccountId "Demo" "bob") reg
                                |> Expect.equal Nothing

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            , Test.test "returns normalized username for account" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "Demo" "Alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.displayUsernameForAccount "Demo" (ContributorAccount.newAccountId "Demo" "alice") reg
                                |> Expect.equal (Just "alice")

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            ]
        , Test.describe "promoteContributorToTrustedAtWiki"
            [ Test.test "promotes contributor to trusted" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.promoteContributorToTrustedAtWiki "Demo" "alice" reg
                                |> Result.map
                                    (\next ->
                                        WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" "alice") next
                                    )
                                |> Expect.equal (Ok True)

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            , Test.test "fails for unknown username" <|
                \() ->
                    WikiContributors.promoteContributorToTrustedAtWiki "Demo" "nobody" WikiContributors.emptyRegistry
                        |> Expect.equal (Err WikiAdminUsers.PromoteTargetNotFound)
            , Test.test "fails for trusted user" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.promoteContributorToTrustedAtWiki "Demo" "trusty" reg
                                |> Expect.equal (Err WikiAdminUsers.PromoteTargetNotContributor)

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "fails for admin user" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.promoteContributorToTrustedAtWiki "Demo" "adminuser" reg
                                |> Expect.equal (Err WikiAdminUsers.PromoteTargetNotContributor)

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.fuzz (Fuzz.intRange 0 99999) "promoted user is trusted moderator" <|
                \n ->
                    let
                        username : String
                        username =
                            "promo" ++ String.fromInt n
                    in
                    case WikiContributors.seedContributorAtWiki "Demo" username "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            case WikiContributors.promoteContributorToTrustedAtWiki "Demo" username reg of
                                Ok next ->
                                    WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" username) next
                                        |> Expect.equal True

                                Err _ ->
                                    Expect.fail "expected promote to succeed"

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            ]
        , Test.describe "demoteTrustedToContributorAtWiki"
            [ Test.test "demotes trusted to contributor" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.demoteTrustedToContributorAtWiki "Demo" "trusty" reg
                                |> Result.map
                                    (\next ->
                                        WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" "trusty") next
                                    )
                                |> Expect.equal (Ok False)

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "fails for unknown username" <|
                \() ->
                    WikiContributors.demoteTrustedToContributorAtWiki "Demo" "nobody" WikiContributors.emptyRegistry
                        |> Expect.equal (Err WikiAdminUsers.DemoteTargetNotFound)
            , Test.test "fails for standard contributor" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.demoteTrustedToContributorAtWiki "Demo" "alice" reg
                                |> Expect.equal (Err WikiAdminUsers.DemoteTargetNotTrusted)

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            , Test.test "fails for admin user" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.demoteTrustedToContributorAtWiki "Demo" "adminuser" reg
                                |> Expect.equal (Err WikiAdminUsers.DemoteTargetNotTrusted)

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.fuzz (Fuzz.intRange 0 99999) "demoted user is not trusted moderator" <|
                \n ->
                    let
                        username : String
                        username =
                            "demfuzz" ++ String.fromInt n
                    in
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" username "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            case WikiContributors.demoteTrustedToContributorAtWiki "Demo" username reg of
                                Ok next ->
                                    WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" username) next
                                        |> Expect.equal False

                                Err _ ->
                                    Expect.fail "expected demote to succeed"

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            ]
        , Test.describe "grantTrustedToAdminAtWiki"
            [ Test.test "grants trusted user wiki admin" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.grantTrustedToAdminAtWiki "Demo" "trusty" reg
                                |> Result.map
                                    (\next ->
                                        WikiContributors.isAdminForWiki "Demo" (ContributorAccount.newAccountId "Demo" "trusty") next
                                    )
                                |> Expect.equal (Ok True)

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "fails for unknown username" <|
                \() ->
                    WikiContributors.grantTrustedToAdminAtWiki "Demo" "nobody" WikiContributors.emptyRegistry
                        |> Expect.equal (Err WikiAdminUsers.GrantTrustedTargetNotFound)
            , Test.test "fails for standard contributor" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.grantTrustedToAdminAtWiki "Demo" "alice" reg
                                |> Expect.equal (Err WikiAdminUsers.GrantTrustedTargetNotTrusted)

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            , Test.test "fails for admin user" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.grantTrustedToAdminAtWiki "Demo" "adminuser" reg
                                |> Expect.equal (Err WikiAdminUsers.GrantTrustedTargetNotTrusted)

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.fuzz (Fuzz.intRange 0 99999) "granted user is wiki admin" <|
                \n ->
                    let
                        username : String
                        username =
                            "grantfuzz" ++ String.fromInt n
                    in
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" username "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            case WikiContributors.grantTrustedToAdminAtWiki "Demo" username reg of
                                Ok next ->
                                    WikiContributors.isAdminForWiki "Demo" (ContributorAccount.newAccountId "Demo" username) next
                                        |> Expect.equal True

                                Err _ ->
                                    Expect.fail "expected grant to succeed"

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            ]
        , Test.describe "revokeAdminToTrustedAtWiki"
            [ Test.test "revokes another admin to trusted" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "admin_a" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg1 ->
                            case WikiContributors.seedAdminContributorAtWiki "Demo" "admin_b" "password12" wikis reg1 of
                                Ok reg2 ->
                                    let
                                        actorId : ContributorAccount.Id
                                        actorId =
                                            ContributorAccount.newAccountId "Demo" "admin_a"
                                    in
                                    case WikiContributors.revokeAdminToTrustedAtWiki "Demo" actorId "admin_b" reg2 of
                                        Ok next ->
                                            ( WikiContributors.isAdminForWiki "Demo" (ContributorAccount.newAccountId "Demo" "admin_b") next
                                            , WikiContributors.isTrustedForWiki "Demo" (ContributorAccount.newAccountId "Demo" "admin_b") next
                                            )
                                                |> Expect.equal ( False, True )

                                        Err _ ->
                                            Expect.fail "expected revoke to succeed"

                                Err _ ->
                                    Expect.fail "expected second admin seed to succeed"

                        Err _ ->
                            Expect.fail "expected first admin seed to succeed"
            , Test.test "cannot revoke self" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "solo_admin" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            let
                                actorId : ContributorAccount.Id
                                actorId =
                                    ContributorAccount.newAccountId "Demo" "solo_admin"
                            in
                            WikiContributors.revokeAdminToTrustedAtWiki "Demo" actorId "solo_admin" reg
                                |> Expect.equal (Err WikiAdminUsers.RevokeAdminCannotRevokeSelf)

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "fails for unknown username" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "actor" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.revokeAdminToTrustedAtWiki "Demo" (ContributorAccount.newAccountId "Demo" "actor") "nobody" reg
                                |> Expect.equal (Err WikiAdminUsers.RevokeAdminTargetNotFound)

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "fails for standard contributor" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg1 ->
                            case WikiContributors.seedAdminContributorAtWiki "Demo" "actor" "password12" wikis reg1 of
                                Ok reg2 ->
                                    WikiContributors.revokeAdminToTrustedAtWiki "Demo" (ContributorAccount.newAccountId "Demo" "actor") "alice" reg2
                                        |> Expect.equal (Err WikiAdminUsers.RevokeAdminTargetNotAdmin)

                                Err _ ->
                                    Expect.fail "expected admin seed to succeed"

                        Err _ ->
                            Expect.fail "expected contributor seed to succeed"
            , Test.test "fails for trusted non-admin" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "Demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg1 ->
                            case WikiContributors.seedAdminContributorAtWiki "Demo" "actor" "password12" wikis reg1 of
                                Ok reg2 ->
                                    WikiContributors.revokeAdminToTrustedAtWiki "Demo" (ContributorAccount.newAccountId "Demo" "actor") "trusty" reg2
                                        |> Expect.equal (Err WikiAdminUsers.RevokeAdminTargetNotAdmin)

                                Err _ ->
                                    Expect.fail "expected admin seed to succeed"

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "revoked admin is not wiki admin for server-side listing check" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "Demo" "admin_a" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg1 ->
                            case WikiContributors.seedAdminContributorAtWiki "Demo" "admin_b" "password12" wikis reg1 of
                                Ok reg2 ->
                                    let
                                        actorId : ContributorAccount.Id
                                        actorId =
                                            ContributorAccount.newAccountId "Demo" "admin_a"
                                    in
                                    case WikiContributors.revokeAdminToTrustedAtWiki "Demo" actorId "admin_b" reg2 of
                                        Ok next ->
                                            let
                                                targetId : ContributorAccount.Id
                                                targetId =
                                                    ContributorAccount.newAccountId "Demo" "admin_b"
                                            in
                                            WikiContributors.isAdminForWiki "Demo" targetId next
                                                |> Expect.equal False

                                        Err _ ->
                                            Expect.fail "expected revoke to succeed"

                                Err _ ->
                                    Expect.fail "expected second admin seed to succeed"

                        Err _ ->
                            Expect.fail "expected first admin seed to succeed"
            ]
        , Test.describe "renameWikiSlug"
            [ Test.test "moves bucket and remaps ids" <|
                \() ->
                    case WikiContributors.attemptRegister "Demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            let
                                next : WikiContributors.Registry
                                next =
                                    WikiContributors.renameWikiSlug "Demo" "Renamed" reg

                                renamedWiki : Wiki.Wiki
                                renamedWiki =
                                    { demoWiki | slug = "Renamed" }

                                wikisAfterRename : Dict.Dict Wiki.Slug Wiki.Wiki
                                wikisAfterRename =
                                    wikis
                                        |> Dict.remove "Demo"
                                        |> Dict.insert "Renamed" renamedWiki

                                newId : ContributorAccount.Id
                                newId =
                                    ContributorAccount.newAccountId "Renamed" "alice"
                            in
                            Expect.all
                                [ \() ->
                                    Dict.get "Demo" next
                                        |> Expect.equal Nothing
                                , \() ->
                                    WikiContributors.roleForAccount "Renamed" newId next
                                        |> Expect.equal (Just WikiRole.UntrustedContributor)
                                , \() ->
                                    WikiContributors.attemptLogin "Renamed" "alice" "password12" wikisAfterRename next
                                        |> Expect.equal (Ok newId)
                                ]
                                ()

                        Err _ ->
                            Expect.fail "expected register to succeed"
            , Test.test "no-op when old slug missing" <|
                \() ->
                    WikiContributors.renameWikiSlug "missing" "X" WikiContributors.emptyRegistry
                        |> Expect.equal WikiContributors.emptyRegistry
            ]
        ]
