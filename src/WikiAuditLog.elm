module WikiAuditLog exposing
    ( AuditEvent
    , AuditEventKind(..)
    , AuditEventKindFilterTag(..)
    , AuditLogFilter
    , Error(..)
    , append
    , auditLogFilterCacheKey
    , emptyAuditLogFilter
    , errorToUserText
    , eventKindFilterTagOptions
    , eventKindFilterTagToString
    , eventKindUserText
    , eventMatchesFilter
    , filterEvents
    , formatEventRowText
    )

import Dict exposing (Dict)
import Wiki


{-| Single append-only audit row for a wiki (story 25).
-}
type alias AuditEvent =
    { atMillis : Int
    , actorUsername : String
    , kind : AuditEventKind
    }


type AuditEventKind
    = ApprovedSubmission { submissionId : String, pageSlug : String }
    | RejectedSubmission { submissionId : String, pageSlug : String }
    | RequestedSubmissionChanges { submissionId : String, pageSlug : String }
    | PromotedContributorToTrusted { targetUsername : String }
    | DemotedTrustedToContributor { targetUsername : String }
    | GrantedWikiAdmin { targetUsername : String }
    | RevokedWikiAdmin { targetUsername : String }
    | TrustedPublishedNewPage { pageSlug : String }
    | TrustedPublishedPageEdit { pageSlug : String }
    | TrustedPublishedPageDelete { pageSlug : String }


{-| Selectable audit event categories for filtering (story 26).
-}
type AuditEventKindFilterTag
    = ApprovedSubmissionKind
    | RejectedSubmissionKind
    | RequestedSubmissionChangesKind
    | PromotedContributorToTrustedKind
    | DemotedTrustedToContributorKind
    | GrantedWikiAdminKind
    | RevokedWikiAdminKind
    | TrustedPublishedNewPageKind
    | TrustedPublishedPageEditKind
    | TrustedPublishedPageDeleteKind


{-| Substrings are case-insensitive; empty string means no constraint on that axis.
`eventKindTags` empty means all kinds; otherwise an event matches if its kind matches any listed tag.
-}
type alias AuditLogFilter =
    { actorUsernameSubstring : String
    , pageSlugSubstring : String
    , eventKindTags : List AuditEventKindFilterTag
    }


emptyAuditLogFilter : AuditLogFilter
emptyAuditLogFilter =
    { actorUsernameSubstring = ""
    , pageSlugSubstring = ""
    , eventKindTags = []
    }


auditLogFilterCacheKey : AuditLogFilter -> String
auditLogFilterCacheKey f =
    let
        kindsPart : String
        kindsPart =
            f.eventKindTags
                |> List.map eventKindFilterTagToString
                |> List.sort
                |> String.join ","
    in
    String.toLower f.actorUsernameSubstring
        ++ "\u{001E}"
        ++ String.toLower f.pageSlugSubstring
        ++ "\u{001E}"
        ++ kindsPart


eventKindFilterTagToString : AuditEventKindFilterTag -> String
eventKindFilterTagToString tag =
    case tag of
        ApprovedSubmissionKind ->
            "approved_submission"

        RejectedSubmissionKind ->
            "rejected_submission"

        RequestedSubmissionChangesKind ->
            "requested_submission_changes"

        PromotedContributorToTrustedKind ->
            "promoted_contributor_to_trusted"

        DemotedTrustedToContributorKind ->
            "demoted_trusted_to_contributor"

        GrantedWikiAdminKind ->
            "granted_wiki_admin"

        RevokedWikiAdminKind ->
            "revoked_wiki_admin"

        TrustedPublishedNewPageKind ->
            "trusted_published_new_page"

        TrustedPublishedPageEditKind ->
            "trusted_published_page_edit"

        TrustedPublishedPageDeleteKind ->
            "trusted_published_page_delete"


eventKindFilterTagOptions : List ( AuditEventKindFilterTag, String )
eventKindFilterTagOptions =
    [ ( ApprovedSubmissionKind, "Approved submission" )
    , ( RejectedSubmissionKind, "Rejected submission" )
    , ( RequestedSubmissionChangesKind, "Requested changes" )
    , ( PromotedContributorToTrustedKind, "Promoted to trusted" )
    , ( DemotedTrustedToContributorKind, "Demoted to contributor" )
    , ( GrantedWikiAdminKind, "Granted wiki admin" )
    , ( RevokedWikiAdminKind, "Revoked wiki admin" )
    , ( TrustedPublishedNewPageKind, "Trusted publish: new page" )
    , ( TrustedPublishedPageEditKind, "Trusted publish: edit" )
    , ( TrustedPublishedPageDeleteKind, "Trusted publish: delete" )
    ]


relatedPageSlugForKind : AuditEventKind -> Maybe String
relatedPageSlugForKind kind =
    case kind of
        ApprovedSubmission { pageSlug } ->
            Just pageSlug

        RejectedSubmission { pageSlug } ->
            Just pageSlug

        RequestedSubmissionChanges { pageSlug } ->
            Just pageSlug

        PromotedContributorToTrusted _ ->
            Nothing

        DemotedTrustedToContributor _ ->
            Nothing

        GrantedWikiAdmin _ ->
            Nothing

        RevokedWikiAdmin _ ->
            Nothing

        TrustedPublishedNewPage { pageSlug } ->
            Just pageSlug

        TrustedPublishedPageEdit { pageSlug } ->
            Just pageSlug

        TrustedPublishedPageDelete { pageSlug } ->
            Just pageSlug


kindMatchesFilterTag : AuditEventKind -> AuditEventKindFilterTag -> Bool
kindMatchesFilterTag kind tag =
    case ( kind, tag ) of
        ( ApprovedSubmission _, ApprovedSubmissionKind ) ->
            True

        ( RejectedSubmission _, RejectedSubmissionKind ) ->
            True

        ( RequestedSubmissionChanges _, RequestedSubmissionChangesKind ) ->
            True

        ( PromotedContributorToTrusted _, PromotedContributorToTrustedKind ) ->
            True

        ( DemotedTrustedToContributor _, DemotedTrustedToContributorKind ) ->
            True

        ( GrantedWikiAdmin _, GrantedWikiAdminKind ) ->
            True

        ( RevokedWikiAdmin _, RevokedWikiAdminKind ) ->
            True

        ( TrustedPublishedNewPage _, TrustedPublishedNewPageKind ) ->
            True

        ( TrustedPublishedPageEdit _, TrustedPublishedPageEditKind ) ->
            True

        ( TrustedPublishedPageDelete _, TrustedPublishedPageDeleteKind ) ->
            True

        _ ->
            False


kindMatchesAnySelectedTag : List AuditEventKindFilterTag -> AuditEventKind -> Bool
kindMatchesAnySelectedTag tags kind =
    case tags of
        [] ->
            True

        _ ->
            List.any (kindMatchesFilterTag kind) tags


{-| Pure predicate for audit filtering (story 26).
-}
eventMatchesFilter : AuditLogFilter -> AuditEvent -> Bool
eventMatchesFilter f ev =
    let
        actorOk : Bool
        actorOk =
            if String.isEmpty (String.trim f.actorUsernameSubstring) then
                True

            else
                String.contains
                    (String.toLower (String.trim f.actorUsernameSubstring))
                    (String.toLower ev.actorUsername)

        pageOk : Bool
        pageOk =
            if String.isEmpty (String.trim f.pageSlugSubstring) then
                True

            else
                case relatedPageSlugForKind ev.kind of
                    Nothing ->
                        False

                    Just slug ->
                        String.contains
                            (String.toLower (String.trim f.pageSlugSubstring))
                            (String.toLower slug)

        kindOk : Bool
        kindOk =
            kindMatchesAnySelectedTag f.eventKindTags ev.kind
    in
    actorOk && pageOk && kindOk


filterEvents : AuditLogFilter -> List AuditEvent -> List AuditEvent
filterEvents f =
    List.filter (eventMatchesFilter f)


type Error
    = WikiNotFound
    | WikiInactive
    | NotLoggedIn
    | WrongWikiSession
    | Forbidden


errorToUserText : Error -> String
errorToUserText err =
    case err of
        WikiNotFound ->
            "This wiki was not found."

        WikiInactive ->
            "This wiki is currently paused."

        NotLoggedIn ->
            "You must be logged in to view the audit log."

        WrongWikiSession ->
            "Switch to this wiki while logged in to view its audit log."

        Forbidden ->
            "Only wiki admins can view the audit log."


{-| Append one event for a wiki (chronological: older events stay earlier in the list).
-}
append :
    Wiki.Slug
    -> Int
    -> String
    -> AuditEventKind
    -> Dict Wiki.Slug (List AuditEvent)
    -> Dict Wiki.Slug (List AuditEvent)
append wikiSlug atMillis actorUsername kind dict =
    let
        ev : AuditEvent
        ev =
            { atMillis = atMillis
            , actorUsername = actorUsername
            , kind = kind
            }
    in
    Dict.update wikiSlug
        (\mv ->
            Just (Maybe.withDefault [] mv ++ [ ev ])
        )
        dict


millisToAuditTimeLabel : Int -> String
millisToAuditTimeLabel m =
    "t=" ++ String.fromInt m


eventKindUserText : AuditEventKind -> String
eventKindUserText kind =
    case kind of
        ApprovedSubmission { submissionId, pageSlug } ->
            "Approved submission "
                ++ submissionId
                ++ " (page "
                ++ pageSlug
                ++ ")"

        RejectedSubmission { submissionId, pageSlug } ->
            "Rejected submission "
                ++ submissionId
                ++ " (page "
                ++ pageSlug
                ++ ")"

        RequestedSubmissionChanges { submissionId, pageSlug } ->
            "Requested changes on submission "
                ++ submissionId
                ++ " (page "
                ++ pageSlug
                ++ ")"

        PromotedContributorToTrusted { targetUsername } ->
            "Promoted contributor " ++ targetUsername ++ " to trusted"

        DemotedTrustedToContributor { targetUsername } ->
            "Demoted trusted contributor " ++ targetUsername ++ " to contributor"

        GrantedWikiAdmin { targetUsername } ->
            "Granted wiki admin to " ++ targetUsername

        RevokedWikiAdmin { targetUsername } ->
            "Revoked wiki admin from " ++ targetUsername

        TrustedPublishedNewPage { pageSlug } ->
            "Trusted publish: created page " ++ pageSlug

        TrustedPublishedPageEdit { pageSlug } ->
            "Trusted publish: edited page " ++ pageSlug

        TrustedPublishedPageDelete { pageSlug } ->
            "Trusted publish: deleted page " ++ pageSlug


formatEventRowText : AuditEvent -> String
formatEventRowText e =
    millisToAuditTimeLabel e.atMillis
        ++ " · "
        ++ e.actorUsername
        ++ " — "
        ++ eventKindUserText e.kind
