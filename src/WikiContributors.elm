module WikiContributors exposing
    ( Registry
    , StoredContributor
    , attemptLogin
    , attemptRegister
    , displayUsernameForAccount
    , emptyRegistry
    , isAdminForWiki
    , isTrustedForWiki
    , demoteTrustedToContributorAtWiki
    , grantTrustedToAdminAtWiki
    , promoteContributorToTrustedAtWiki
    , revokeAdminToTrustedAtWiki
    , seedAdminContributorAtWiki
    , seedContributorAtWiki
    , seedTrustedContributorAtWiki
    , usersForWikiListing
    )

import ContributorAccount
import Dict exposing (Dict)
import Wiki
import WikiAdminUsers
import WikiRole


type alias StoredContributor =
    { id : ContributorAccount.Id
    , passwordVerifier : ContributorAccount.Verifier
    , role : WikiRole.WikiRole
    }


{-| Per-wiki map of normalized username → account.
-}
type alias Registry =
    Dict Wiki.Slug (Dict String StoredContributor)


emptyRegistry : Registry
emptyRegistry =
    Dict.empty


attemptRegister :
    Wiki.Slug
    -> String
    -> String
    -> Dict Wiki.Slug Wiki.Wiki
    -> Registry
    -> Result ContributorAccount.RegisterContributorError ( Registry, ContributorAccount.Id )
attemptRegister wikiSlug rawUsername plainPassword wikis registry =
    case Dict.get wikiSlug wikis of
        Nothing ->
            Err ContributorAccount.RegisterWikiNotFound

        Just _ ->
            case ContributorAccount.validateRegistrationFields rawUsername plainPassword of
                Err e ->
                    Err e

                Ok { normalizedUsername, password } ->
                    let
                        byWiki : Dict String StoredContributor
                        byWiki =
                            registry
                                |> Dict.get wikiSlug
                                |> Maybe.withDefault Dict.empty
                    in
                    case Dict.get normalizedUsername byWiki of
                        Just _ ->
                            Err ContributorAccount.RegisterUsernameTaken

                        Nothing ->
                            let
                                id : ContributorAccount.Id
                                id =
                                    ContributorAccount.newAccountId wikiSlug normalizedUsername

                                stored : StoredContributor
                                stored =
                                    { id = id
                                    , passwordVerifier = ContributorAccount.verifierFromPassword password
                                    , role = WikiRole.Contributor
                                    }

                                nextByWiki : Dict String StoredContributor
                                nextByWiki =
                                    Dict.insert normalizedUsername stored byWiki

                                nextRegistry : Registry
                                nextRegistry =
                                    Dict.insert wikiSlug nextByWiki registry
                            in
                            Ok ( nextRegistry, id )


{-| Normalized username for an account on this wiki, if registered.
-}
displayUsernameForAccount : Wiki.Slug -> ContributorAccount.Id -> Registry -> Maybe String
displayUsernameForAccount wikiSlug accountId registry =
    case Dict.get wikiSlug registry of
        Nothing ->
            Nothing

        Just byWiki ->
            byWiki
                |> Dict.toList
                |> List.filter (\( _, stored ) -> stored.id == accountId)
                |> List.head
                |> Maybe.map Tuple.first


{-| True when `accountId` is a contributor on `wikiSlug` with trusted-moderator status (trusted or admin).
-}
isTrustedForWiki : Wiki.Slug -> ContributorAccount.Id -> Registry -> Bool
isTrustedForWiki wikiSlug accountId registry =
    registry
        |> Dict.get wikiSlug
        |> Maybe.withDefault Dict.empty
        |> Dict.values
        |> List.any
            (\stored ->
                stored.id == accountId && WikiRole.isTrustedModerator stored.role
            )


{-| True when `accountId` is a wiki admin on `wikiSlug`.
-}
isAdminForWiki : Wiki.Slug -> ContributorAccount.Id -> Registry -> Bool
isAdminForWiki wikiSlug accountId registry =
    registry
        |> Dict.get wikiSlug
        |> Maybe.withDefault Dict.empty
        |> Dict.values
        |> List.any
            (\stored ->
                stored.id == accountId && WikiRole.canAccessWikiAdminUsers stored.role
            )


{-| Sorted directory row list for an admin response (no passwords).
-}
usersForWikiListing : Wiki.Slug -> Registry -> List WikiAdminUsers.ListedUser
usersForWikiListing wikiSlug registry =
    registry
        |> Dict.get wikiSlug
        |> Maybe.withDefault Dict.empty
        |> Dict.toList
        |> List.map
            (\( username, stored ) ->
                { username = username
                , role = stored.role
                }
            )
        |> List.sortBy .username


attemptLogin :
    Wiki.Slug
    -> String
    -> String
    -> Dict Wiki.Slug Wiki.Wiki
    -> Registry
    -> Result ContributorAccount.LoginContributorError ContributorAccount.Id
attemptLogin wikiSlug rawUsername plainPassword wikis registry =
    case Dict.get wikiSlug wikis of
        Nothing ->
            Err ContributorAccount.LoginWikiNotFound

        Just _ ->
            case ContributorAccount.validateLoginFields rawUsername plainPassword of
                Err e ->
                    Err e

                Ok { normalizedUsername, password } ->
                    let
                        byWiki : Dict String StoredContributor
                        byWiki =
                            registry
                                |> Dict.get wikiSlug
                                |> Maybe.withDefault Dict.empty
                    in
                    case Dict.get normalizedUsername byWiki of
                        Nothing ->
                            Err ContributorAccount.LoginInvalidCredentials

                        Just stored ->
                            if ContributorAccount.verifierMatchesPassword password stored.passwordVerifier then
                                Ok stored.id

                            else
                                Err ContributorAccount.LoginInvalidCredentials


{-| Insert a contributor for backend seed data (same rules as registration). Contributor role.
-}
seedContributorAtWiki :
    Wiki.Slug
    -> String
    -> String
    -> Dict Wiki.Slug Wiki.Wiki
    -> Registry
    -> Result ContributorAccount.RegisterContributorError Registry
seedContributorAtWiki wikiSlug rawUsername plainPassword wikis registry =
    seedContributorAtWikiWithRole WikiRole.Contributor wikiSlug rawUsername plainPassword wikis registry


{-| Seed a trusted contributor (demo / tests; story 14).
-}
seedTrustedContributorAtWiki :
    Wiki.Slug
    -> String
    -> String
    -> Dict Wiki.Slug Wiki.Wiki
    -> Registry
    -> Result ContributorAccount.RegisterContributorError Registry
seedTrustedContributorAtWiki wikiSlug rawUsername plainPassword wikis registry =
    seedContributorAtWikiWithRole WikiRole.Trusted wikiSlug rawUsername plainPassword wikis registry


{-| Seed a wiki admin (story 20).
-}
seedAdminContributorAtWiki :
    Wiki.Slug
    -> String
    -> String
    -> Dict Wiki.Slug Wiki.Wiki
    -> Registry
    -> Result ContributorAccount.RegisterContributorError Registry
seedAdminContributorAtWiki wikiSlug rawUsername plainPassword wikis registry =
    seedContributorAtWikiWithRole WikiRole.Admin wikiSlug rawUsername plainPassword wikis registry


seedContributorAtWikiWithRole :
    WikiRole.WikiRole
    -> Wiki.Slug
    -> String
    -> String
    -> Dict Wiki.Slug Wiki.Wiki
    -> Registry
    -> Result ContributorAccount.RegisterContributorError Registry
seedContributorAtWikiWithRole role wikiSlug rawUsername plainPassword wikis registry =
    case Dict.get wikiSlug wikis of
        Nothing ->
            Err ContributorAccount.RegisterWikiNotFound

        Just _ ->
            case ContributorAccount.validateRegistrationFields rawUsername plainPassword of
                Err e ->
                    Err e

                Ok { normalizedUsername, password } ->
                    let
                        byWiki : Dict String StoredContributor
                        byWiki =
                            registry
                                |> Dict.get wikiSlug
                                |> Maybe.withDefault Dict.empty
                    in
                    case Dict.get normalizedUsername byWiki of
                        Just _ ->
                            Err ContributorAccount.RegisterUsernameTaken

                        Nothing ->
                            let
                                id : ContributorAccount.Id
                                id =
                                    ContributorAccount.newAccountId wikiSlug normalizedUsername

                                stored : StoredContributor
                                stored =
                                    { id = id
                                    , passwordVerifier = ContributorAccount.verifierFromPassword password
                                    , role = role
                                    }

                                nextByWiki : Dict String StoredContributor
                                nextByWiki =
                                    Dict.insert normalizedUsername stored byWiki

                                nextRegistry : Registry
                                nextRegistry =
                                    Dict.insert wikiSlug nextByWiki registry
                            in
                            Ok nextRegistry


{-| Promote a user by normalized username (story 21). Fails if missing or not a contributor.
-}
promoteContributorToTrustedAtWiki :
    Wiki.Slug
    -> String
    -> Registry
    -> Result WikiAdminUsers.PromoteContributorError Registry
promoteContributorToTrustedAtWiki wikiSlug normalizedUsername registry =
    let
        byWiki : Dict String StoredContributor
        byWiki =
            registry
                |> Dict.get wikiSlug
                |> Maybe.withDefault Dict.empty
    in
    case Dict.get normalizedUsername byWiki of
        Nothing ->
            Err WikiAdminUsers.PromoteTargetNotFound

        Just stored ->
            case WikiRole.promoteContributorToTrusted stored.role of
                Nothing ->
                    Err WikiAdminUsers.PromoteTargetNotContributor

                Just newRole ->
                    let
                        nextStored : StoredContributor
                        nextStored =
                            { stored | role = newRole }

                        nextByWiki : Dict String StoredContributor
                        nextByWiki =
                            Dict.insert normalizedUsername nextStored byWiki
                    in
                    Ok (Dict.insert wikiSlug nextByWiki registry)


{-| Grant wiki admin to a trusted user by normalized username (story 23).
-}
grantTrustedToAdminAtWiki :
    Wiki.Slug
    -> String
    -> Registry
    -> Result WikiAdminUsers.GrantTrustedToAdminError Registry
grantTrustedToAdminAtWiki wikiSlug normalizedUsername registry =
    let
        byWiki : Dict String StoredContributor
        byWiki =
            registry
                |> Dict.get wikiSlug
                |> Maybe.withDefault Dict.empty
    in
    case Dict.get normalizedUsername byWiki of
        Nothing ->
            Err WikiAdminUsers.GrantTrustedTargetNotFound

        Just stored ->
            case WikiRole.grantTrustedToAdmin stored.role of
                Nothing ->
                    Err WikiAdminUsers.GrantTrustedTargetNotTrusted

                Just newRole ->
                    let
                        nextStored : StoredContributor
                        nextStored =
                            { stored | role = newRole }

                        nextByWiki : Dict String StoredContributor
                        nextByWiki =
                            Dict.insert normalizedUsername nextStored byWiki
                    in
                    Ok (Dict.insert wikiSlug nextByWiki registry)


{-| Revoke wiki admin for another user by normalized username (story 24). Fails if missing, not admin, or target is the actor.
-}
revokeAdminToTrustedAtWiki :
    Wiki.Slug
    -> ContributorAccount.Id
    -> String
    -> Registry
    -> Result WikiAdminUsers.RevokeAdminError Registry
revokeAdminToTrustedAtWiki wikiSlug actorAccountId normalizedTargetUsername registry =
    let
        byWiki : Dict String StoredContributor
        byWiki =
            registry
                |> Dict.get wikiSlug
                |> Maybe.withDefault Dict.empty
    in
    case Dict.get normalizedTargetUsername byWiki of
        Nothing ->
            Err WikiAdminUsers.RevokeAdminTargetNotFound

        Just stored ->
            if stored.id == actorAccountId then
                Err WikiAdminUsers.RevokeAdminCannotRevokeSelf

            else
                case WikiRole.revokeAdminToTrusted stored.role of
                    Nothing ->
                        Err WikiAdminUsers.RevokeAdminTargetNotAdmin

                    Just newRole ->
                        let
                            nextStored : StoredContributor
                            nextStored =
                                { stored | role = newRole }

                            nextByWiki : Dict String StoredContributor
                            nextByWiki =
                                Dict.insert normalizedTargetUsername nextStored byWiki
                        in
                        Ok (Dict.insert wikiSlug nextByWiki registry)


{-| Demote a user by normalized username (story 22). Fails if missing or not trusted.
-}
demoteTrustedToContributorAtWiki :
    Wiki.Slug
    -> String
    -> Registry
    -> Result WikiAdminUsers.DemoteTrustedError Registry
demoteTrustedToContributorAtWiki wikiSlug normalizedUsername registry =
    let
        byWiki : Dict String StoredContributor
        byWiki =
            registry
                |> Dict.get wikiSlug
                |> Maybe.withDefault Dict.empty
    in
    case Dict.get normalizedUsername byWiki of
        Nothing ->
            Err WikiAdminUsers.DemoteTargetNotFound

        Just stored ->
            case WikiRole.demoteTrustedToContributor stored.role of
                Nothing ->
                    Err WikiAdminUsers.DemoteTargetNotTrusted

                Just newRole ->
                    let
                        nextStored : StoredContributor
                        nextStored =
                            { stored | role = newRole }

                        nextByWiki : Dict String StoredContributor
                        nextByWiki =
                            Dict.insert normalizedUsername nextStored byWiki
                    in
                    Ok (Dict.insert wikiSlug nextByWiki registry)
