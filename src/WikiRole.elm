module WikiRole exposing
    ( WikiRole(..)
    , backupTagDecoder
    , backupTagEncode
    , canAccessWikiAdminUsers
    , demoteTrustedToContributor
    , grantTrustedToAdmin
    , isTrustedModerator
    , label
    , promoteContributorToTrusted
    , revokeAdminToTrusted
    )

import Json.Decode as Decode


{-| Per-wiki contributor capability tier (stories 14, 20).
-}
type WikiRole
    = UntrustedContributor
    | TrustedContributor
    | Admin


{-| Wiki admin UI (`/w/:wikiSlug/admin/users`); trusted-only is insufficient (story 20; story 33 will harden server-side).
-}
canAccessWikiAdminUsers : WikiRole -> Bool
canAccessWikiAdminUsers role =
    case role of
        UntrustedContributor ->
            False

        TrustedContributor ->
            False

        Admin ->
            True


{-| Direct publish and review-queue access (stories 14–19).
-}
isTrustedModerator : WikiRole -> Bool
isTrustedModerator role =
    case role of
        UntrustedContributor ->
            False

        TrustedContributor ->
            True

        Admin ->
            True


{-| Admin promotion (story 21): only a standard contributor becomes trusted.
-}
promoteContributorToTrusted : WikiRole -> Maybe WikiRole
promoteContributorToTrusted role =
    case role of
        UntrustedContributor ->
            Just TrustedContributor

        TrustedContributor ->
            Nothing

        Admin ->
            Nothing


{-| Admin demotion (story 22): only a trusted contributor becomes a standard contributor.
-}
demoteTrustedToContributor : WikiRole -> Maybe WikiRole
demoteTrustedToContributor role =
    case role of
        UntrustedContributor ->
            Nothing

        TrustedContributor ->
            Just UntrustedContributor

        Admin ->
            Nothing


{-| Wiki admin grants admin (story 23): only a trusted contributor becomes admin.
-}
grantTrustedToAdmin : WikiRole -> Maybe WikiRole
grantTrustedToAdmin role =
    case role of
        UntrustedContributor ->
            Nothing

        TrustedContributor ->
            Just Admin

        Admin ->
            Nothing


{-| Revoke wiki admin (story 24): admin becomes trusted contributor.
-}
revokeAdminToTrusted : WikiRole -> Maybe WikiRole
revokeAdminToTrusted role =
    case role of
        UntrustedContributor ->
            Nothing

        TrustedContributor ->
            Nothing

        Admin ->
            Just TrustedContributor


label : WikiRole -> String
label role =
    case role of
        UntrustedContributor ->
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
        UntrustedContributor ->
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
                        Decode.succeed UntrustedContributor

                    "trusted_contributor" ->
                        Decode.succeed TrustedContributor

                    "admin" ->
                        Decode.succeed Admin

                    _ ->
                        Decode.fail ("unknown wiki role: " ++ s)
            )
