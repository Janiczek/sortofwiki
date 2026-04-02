module WikiContributorsTest exposing (suite)

import ContributorAccount
import Dict
import Expect
import Fuzz
import Test exposing (Test)
import Wiki
import WikiAdminUsers
import WikiContributors


demoWiki : Wiki.Wiki
demoWiki =
    Wiki.wikiWithPages "demo" "Demo" Dict.empty


wikis : Dict.Dict Wiki.Slug Wiki.Wiki
wikis =
    Dict.singleton "demo" demoWiki


suite : Test
suite =
    Test.describe "WikiContributors"
        [ Test.describe "attemptRegister"
            [ Test.test "registers first account" <|
                \() ->
                    WikiContributors.attemptRegister "demo" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Result.map (Tuple.mapFirst (always ()))
                        |> Expect.equal (Ok ( (), ContributorAccount.newAccountId "demo" "alice" ))
            , Test.test "rejects unknown wiki" <|
                \() ->
                    WikiContributors.attemptRegister "missing" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.RegisterWikiNotFound)
            , Test.test "rejects duplicate username" <|
                \() ->
                    case WikiContributors.attemptRegister "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            WikiContributors.attemptRegister "demo" "Alice" "password12" wikis reg
                                |> Expect.equal (Err ContributorAccount.RegisterUsernameTaken)

                        Err _ ->
                            Expect.fail "expected first register to succeed"
            ]
        , Test.describe "attemptLogin"
            [ Test.test "logs in with correct password" <|
                \() ->
                    case WikiContributors.attemptRegister "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            WikiContributors.attemptLogin "demo" "Alice" "password12" wikis reg
                                |> Expect.equal (Ok (ContributorAccount.newAccountId "demo" "alice"))

                        Err _ ->
                            Expect.fail "expected register to succeed"
            , Test.test "rejects unknown wiki" <|
                \() ->
                    WikiContributors.attemptLogin "missing" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.LoginWikiNotFound)
            , Test.test "rejects unknown username" <|
                \() ->
                    WikiContributors.attemptLogin "demo" "nobody" "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.LoginInvalidCredentials)
            , Test.test "rejects wrong password" <|
                \() ->
                    case WikiContributors.attemptRegister "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            WikiContributors.attemptLogin "demo" "alice" "wrongpass_" wikis reg
                                |> Expect.equal (Err ContributorAccount.LoginInvalidCredentials)

                        Err _ ->
                            Expect.fail "expected register to succeed"
            , Test.test "rejects empty username" <|
                \() ->
                    WikiContributors.attemptLogin "demo" "   " "password12" wikis WikiContributors.emptyRegistry
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
                    case WikiContributors.attemptRegister "demo" username password wikis WikiContributors.emptyRegistry of
                        Ok ( reg, _ ) ->
                            let
                                expectedId : ContributorAccount.Id
                                expectedId =
                                    ContributorAccount.newAccountId "demo" (String.toLower username)
                            in
                            WikiContributors.attemptLogin "demo" username password wikis reg
                                |> Expect.equal (Ok expectedId)

                        Err _ ->
                            Expect.fail "expected register to succeed"
            ]
        , Test.describe "seedContributorAtWiki"
            [ Test.test "inserts same as attemptRegister for empty registry" <|
                \() ->
                    WikiContributors.seedContributorAtWiki "demo" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Result.map
                            (\reg ->
                                WikiContributors.attemptLogin "demo" "alice" "password12" wikis reg
                            )
                        |> Expect.equal (Ok (Ok (ContributorAccount.newAccountId "demo" "alice")))
            , Test.test "rejects unknown wiki" <|
                \() ->
                    WikiContributors.seedContributorAtWiki "missing" "alice" "password12" wikis WikiContributors.emptyRegistry
                        |> Expect.equal (Err ContributorAccount.RegisterWikiNotFound)
            , Test.test "rejects duplicate username" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.seedContributorAtWiki "demo" "Alice" "otherpass12" wikis reg
                                |> Expect.equal (Err ContributorAccount.RegisterUsernameTaken)

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            ]
        , Test.describe "isTrustedForWiki"
            [ Test.test "false for freshly registered contributor" <|
                \() ->
                    case WikiContributors.attemptRegister "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok ( reg, accountId ) ->
                            WikiContributors.isTrustedForWiki "demo" accountId reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected register to succeed"
            , Test.test "true for seeded trusted contributor" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" "trusty") reg
                                |> Expect.equal True

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "true for seeded admin contributor" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" "adminuser") reg
                                |> Expect.equal True

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "false when account id does not match" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" "other") reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "false for trusted user checked on different wiki" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "elm-tips" (ContributorAccount.newAccountId "demo" "trusty") reg
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
                    case WikiContributors.seedContributorAtWiki "demo" username "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" username) reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            ]
        , Test.describe "isAdminForWiki"
            [ Test.test "true for seeded admin" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isAdminForWiki "demo" (ContributorAccount.newAccountId "demo" "adminuser") reg
                                |> Expect.equal True

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "false for seeded trusted" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.isAdminForWiki "demo" (ContributorAccount.newAccountId "demo" "trusty") reg
                                |> Expect.equal False

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            ]
        , Test.describe "displayUsernameForAccount"
            [ Test.test "Nothing for unknown wiki" <|
                \() ->
                    WikiContributors.displayUsernameForAccount "missing" (ContributorAccount.newAccountId "demo" "alice") WikiContributors.emptyRegistry
                        |> Expect.equal Nothing
            , Test.test "Nothing when account not in wiki" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.displayUsernameForAccount "demo" (ContributorAccount.newAccountId "demo" "bob") reg
                                |> Expect.equal Nothing

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            , Test.test "returns normalized username for account" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "demo" "Alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.displayUsernameForAccount "demo" (ContributorAccount.newAccountId "demo" "alice") reg
                                |> Expect.equal (Just "alice")

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            ]
        , Test.describe "promoteContributorToTrustedAtWiki"
            [ Test.test "promotes contributor to trusted" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.promoteContributorToTrustedAtWiki "demo" "alice" reg
                                |> Result.map
                                    (\next ->
                                        WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" "alice") next
                                    )
                                |> Expect.equal (Ok True)

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            , Test.test "fails for unknown username" <|
                \() ->
                    WikiContributors.promoteContributorToTrustedAtWiki "demo" "nobody" WikiContributors.emptyRegistry
                        |> Expect.equal (Err WikiAdminUsers.PromoteTargetNotFound)
            , Test.test "fails for trusted user" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.promoteContributorToTrustedAtWiki "demo" "trusty" reg
                                |> Expect.equal (Err WikiAdminUsers.PromoteTargetNotContributor)

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "fails for admin user" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.promoteContributorToTrustedAtWiki "demo" "adminuser" reg
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
                    case WikiContributors.seedContributorAtWiki "demo" username "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            case WikiContributors.promoteContributorToTrustedAtWiki "demo" username reg of
                                Ok next ->
                                    WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" username) next
                                        |> Expect.equal True

                                Err _ ->
                                    Expect.fail "expected promote to succeed"

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            ]
        , Test.describe "demoteTrustedToContributorAtWiki"
            [ Test.test "demotes trusted to contributor" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.demoteTrustedToContributorAtWiki "demo" "trusty" reg
                                |> Result.map
                                    (\next ->
                                        WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" "trusty") next
                                    )
                                |> Expect.equal (Ok False)

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "fails for unknown username" <|
                \() ->
                    WikiContributors.demoteTrustedToContributorAtWiki "demo" "nobody" WikiContributors.emptyRegistry
                        |> Expect.equal (Err WikiAdminUsers.DemoteTargetNotFound)
            , Test.test "fails for standard contributor" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.demoteTrustedToContributorAtWiki "demo" "alice" reg
                                |> Expect.equal (Err WikiAdminUsers.DemoteTargetNotTrusted)

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            , Test.test "fails for admin user" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.demoteTrustedToContributorAtWiki "demo" "adminuser" reg
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
                    case WikiContributors.seedTrustedContributorAtWiki "demo" username "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            case WikiContributors.demoteTrustedToContributorAtWiki "demo" username reg of
                                Ok next ->
                                    WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" username) next
                                        |> Expect.equal False

                                Err _ ->
                                    Expect.fail "expected demote to succeed"

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            ]
        , Test.describe "grantTrustedToAdminAtWiki"
            [ Test.test "grants trusted user wiki admin" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.grantTrustedToAdminAtWiki "demo" "trusty" reg
                                |> Result.map
                                    (\next ->
                                        WikiContributors.isAdminForWiki "demo" (ContributorAccount.newAccountId "demo" "trusty") next
                                    )
                                |> Expect.equal (Ok True)

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "fails for unknown username" <|
                \() ->
                    WikiContributors.grantTrustedToAdminAtWiki "demo" "nobody" WikiContributors.emptyRegistry
                        |> Expect.equal (Err WikiAdminUsers.GrantTrustedTargetNotFound)
            , Test.test "fails for standard contributor" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.grantTrustedToAdminAtWiki "demo" "alice" reg
                                |> Expect.equal (Err WikiAdminUsers.GrantTrustedTargetNotTrusted)

                        Err _ ->
                            Expect.fail "expected seed to succeed"
            , Test.test "fails for admin user" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "demo" "adminuser" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.grantTrustedToAdminAtWiki "demo" "adminuser" reg
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
                    case WikiContributors.seedTrustedContributorAtWiki "demo" username "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            case WikiContributors.grantTrustedToAdminAtWiki "demo" username reg of
                                Ok next ->
                                    WikiContributors.isAdminForWiki "demo" (ContributorAccount.newAccountId "demo" username) next
                                        |> Expect.equal True

                                Err _ ->
                                    Expect.fail "expected grant to succeed"

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            ]
        , Test.describe "revokeAdminToTrustedAtWiki"
            [ Test.test "revokes another admin to trusted" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "demo" "admin_a" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg1 ->
                            case WikiContributors.seedAdminContributorAtWiki "demo" "admin_b" "password12" wikis reg1 of
                                Ok reg2 ->
                                    let
                                        actorId : ContributorAccount.Id
                                        actorId =
                                            ContributorAccount.newAccountId "demo" "admin_a"
                                    in
                                    case WikiContributors.revokeAdminToTrustedAtWiki "demo" actorId "admin_b" reg2 of
                                        Ok next ->
                                            ( WikiContributors.isAdminForWiki "demo" (ContributorAccount.newAccountId "demo" "admin_b") next
                                            , WikiContributors.isTrustedForWiki "demo" (ContributorAccount.newAccountId "demo" "admin_b") next
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
                    case WikiContributors.seedAdminContributorAtWiki "demo" "solo_admin" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            let
                                actorId : ContributorAccount.Id
                                actorId =
                                    ContributorAccount.newAccountId "demo" "solo_admin"
                            in
                            WikiContributors.revokeAdminToTrustedAtWiki "demo" actorId "solo_admin" reg
                                |> Expect.equal (Err WikiAdminUsers.RevokeAdminCannotRevokeSelf)

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "fails for unknown username" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "demo" "actor" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg ->
                            WikiContributors.revokeAdminToTrustedAtWiki "demo" (ContributorAccount.newAccountId "demo" "actor") "nobody" reg
                                |> Expect.equal (Err WikiAdminUsers.RevokeAdminTargetNotFound)

                        Err _ ->
                            Expect.fail "expected admin seed to succeed"
            , Test.test "fails for standard contributor" <|
                \() ->
                    case WikiContributors.seedContributorAtWiki "demo" "alice" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg1 ->
                            case WikiContributors.seedAdminContributorAtWiki "demo" "actor" "password12" wikis reg1 of
                                Ok reg2 ->
                                    WikiContributors.revokeAdminToTrustedAtWiki "demo" (ContributorAccount.newAccountId "demo" "actor") "alice" reg2
                                        |> Expect.equal (Err WikiAdminUsers.RevokeAdminTargetNotAdmin)

                                Err _ ->
                                    Expect.fail "expected admin seed to succeed"

                        Err _ ->
                            Expect.fail "expected contributor seed to succeed"
            , Test.test "fails for trusted non-admin" <|
                \() ->
                    case WikiContributors.seedTrustedContributorAtWiki "demo" "trusty" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg1 ->
                            case WikiContributors.seedAdminContributorAtWiki "demo" "actor" "password12" wikis reg1 of
                                Ok reg2 ->
                                    WikiContributors.revokeAdminToTrustedAtWiki "demo" (ContributorAccount.newAccountId "demo" "actor") "trusty" reg2
                                        |> Expect.equal (Err WikiAdminUsers.RevokeAdminTargetNotAdmin)

                                Err _ ->
                                    Expect.fail "expected admin seed to succeed"

                        Err _ ->
                            Expect.fail "expected trusted seed to succeed"
            , Test.test "revoked admin is not wiki admin for server-side listing check" <|
                \() ->
                    case WikiContributors.seedAdminContributorAtWiki "demo" "admin_a" "password12" wikis WikiContributors.emptyRegistry of
                        Ok reg1 ->
                            case WikiContributors.seedAdminContributorAtWiki "demo" "admin_b" "password12" wikis reg1 of
                                Ok reg2 ->
                                    let
                                        actorId : ContributorAccount.Id
                                        actorId =
                                            ContributorAccount.newAccountId "demo" "admin_a"
                                    in
                                    case WikiContributors.revokeAdminToTrustedAtWiki "demo" actorId "admin_b" reg2 of
                                        Ok next ->
                                            let
                                                targetId : ContributorAccount.Id
                                                targetId =
                                                    ContributorAccount.newAccountId "demo" "admin_b"
                                            in
                                            WikiContributors.isAdminForWiki "demo" targetId next
                                                |> Expect.equal False

                                        Err _ ->
                                            Expect.fail "expected revoke to succeed"

                                Err _ ->
                                    Expect.fail "expected second admin seed to succeed"

                        Err _ ->
                            Expect.fail "expected first admin seed to succeed"
            ]
        ]
