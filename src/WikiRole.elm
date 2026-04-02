module WikiRole exposing (WikiRole(..), canAccessWikiAdminUsers, demoteTrustedToContributor, grantTrustedToAdmin, isTrustedModerator, label, promoteContributorToTrusted, revokeAdminToTrusted)


{-| Per-wiki contributor capability tier (stories 14, 20).
-}
type WikiRole
    = Contributor
    | Trusted
    | Admin


{-| Wiki admin UI (`/w/:wikiSlug/admin/users`); trusted-only is insufficient (story 20; story 33 will harden server-side).
-}
canAccessWikiAdminUsers : WikiRole -> Bool
canAccessWikiAdminUsers role =
    case role of
        Contributor ->
            False

        Trusted ->
            False

        Admin ->
            True


{-| Direct publish and review-queue access (stories 14–19).
-}
isTrustedModerator : WikiRole -> Bool
isTrustedModerator role =
    case role of
        Contributor ->
            False

        Trusted ->
            True

        Admin ->
            True


{-| Admin promotion (story 21): only a standard contributor becomes trusted.
-}
promoteContributorToTrusted : WikiRole -> Maybe WikiRole
promoteContributorToTrusted role =
    case role of
        Contributor ->
            Just Trusted

        Trusted ->
            Nothing

        Admin ->
            Nothing


{-| Admin demotion (story 22): only a trusted contributor becomes a standard contributor.
-}
demoteTrustedToContributor : WikiRole -> Maybe WikiRole
demoteTrustedToContributor role =
    case role of
        Contributor ->
            Nothing

        Trusted ->
            Just Contributor

        Admin ->
            Nothing


{-| Wiki admin grants admin (story 23): only a trusted contributor becomes admin.
-}
grantTrustedToAdmin : WikiRole -> Maybe WikiRole
grantTrustedToAdmin role =
    case role of
        Contributor ->
            Nothing

        Trusted ->
            Just Admin

        Admin ->
            Nothing


{-| Revoke wiki admin (story 24): admin becomes trusted contributor.
-}
revokeAdminToTrusted : WikiRole -> Maybe WikiRole
revokeAdminToTrusted role =
    case role of
        Contributor ->
            Nothing

        Trusted ->
            Nothing

        Admin ->
            Just Trusted


label : WikiRole -> String
label role =
    case role of
        Contributor ->
            "Contributor"

        Trusted ->
            "Trusted"

        Admin ->
            "Admin"
