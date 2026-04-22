module WikiRole exposing
    ( SubmissionsScope
    , UntrustedContributorCaps
    , WikiRole(..)
    , backupTagDecoder
    , backupTagEncode
    , canAccessWikiAdminUsers
    , defaultUntrustedContributorCaps
    , demoteTrustedToContributor
    , grantTrustedToAdmin
    , hasMySubmissionsAccess
    , isTrustedModerator
    , label
    , promoteContributorToTrusted
    , revokeAdminToTrusted
    )

import Json.Decode as Decode


{-| Author-side submission queue ("My Submissions"); only untrusted contributors carry this in `UntrustedContributorCaps`.
-}
type SubmissionsScope
    = SubmissionsScope


{-| Data only meaningful for the untrusted tier (extensible without widening trusted/admin).
-}
type alias UntrustedContributorCaps =
    { submissions : SubmissionsScope }


{-| Default caps for a newly registered or demoted untrusted contributor.
-}
defaultUntrustedContributorCaps : UntrustedContributorCaps
defaultUntrustedContributorCaps =
    { submissions = SubmissionsScope }


{-| Per-wiki contributor capability tier (untrusted, trusted moderator, wiki admin).
-}
type WikiRole
    = UntrustedContributor UntrustedContributorCaps
    | TrustedContributor
    | Admin


{-| My Submissions list and related author-side submission UI (untrusted only).
-}
hasMySubmissionsAccess : WikiRole -> Bool
hasMySubmissionsAccess role =
    case role of
        UntrustedContributor _ ->
            True

        TrustedContributor ->
            False

        Admin ->
            False


{-| Wiki admin UI (`/w/:wikiSlug/admin/users`); trusted-only is insufficient; server-side checks still apply.
-}
canAccessWikiAdminUsers : WikiRole -> Bool
canAccessWikiAdminUsers role =
    case role of
        UntrustedContributor _ ->
            False

        TrustedContributor ->
            False

        Admin ->
            True


{-| Direct publish and review-queue access.
-}
isTrustedModerator : WikiRole -> Bool
isTrustedModerator role =
    case role of
        UntrustedContributor _ ->
            False

        TrustedContributor ->
            True

        Admin ->
            True


{-| Admin promotion: only a standard contributor becomes trusted.
-}
promoteContributorToTrusted : WikiRole -> Maybe WikiRole
promoteContributorToTrusted role =
    case role of
        UntrustedContributor _ ->
            Just TrustedContributor

        TrustedContributor ->
            Nothing

        Admin ->
            Nothing


{-| Admin demotion: only a trusted contributor becomes a standard contributor.
-}
demoteTrustedToContributor : WikiRole -> Maybe WikiRole
demoteTrustedToContributor role =
    case role of
        UntrustedContributor _ ->
            Nothing

        TrustedContributor ->
            Just (UntrustedContributor defaultUntrustedContributorCaps)

        Admin ->
            Nothing


{-| Wiki admin grants admin: only a trusted contributor becomes admin.
-}
grantTrustedToAdmin : WikiRole -> Maybe WikiRole
grantTrustedToAdmin role =
    case role of
        UntrustedContributor _ ->
            Nothing

        TrustedContributor ->
            Just Admin

        Admin ->
            Nothing


{-| Revoke wiki admin: admin becomes trusted contributor.
-}
revokeAdminToTrusted : WikiRole -> Maybe WikiRole
revokeAdminToTrusted role =
    case role of
        UntrustedContributor _ ->
            Nothing

        TrustedContributor ->
            Nothing

        Admin ->
            Just TrustedContributor


label : WikiRole -> String
label role =
    case role of
        UntrustedContributor _ ->
            "Contributor"

        TrustedContributor ->
            "Trusted"

        Admin ->
            "Admin"


{-| Host-admin JSON backup (stable string tags).
-}
backupTagEncode : WikiRole -> String
backupTagEncode role =
    case role of
        UntrustedContributor _ ->
            "untrusted_contributor"

        TrustedContributor ->
            "trusted_contributor"

        Admin ->
            "admin"


backupTagDecoder : Decode.Decoder WikiRole
backupTagDecoder =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "untrusted_contributor" ->
                        Decode.succeed (UntrustedContributor defaultUntrustedContributorCaps)

                    "trusted_contributor" ->
                        Decode.succeed TrustedContributor

                    "admin" ->
                        Decode.succeed Admin

                    _ ->
                        Decode.fail ("unknown wiki role: " ++ s)
            )
