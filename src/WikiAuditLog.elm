module WikiAuditLog exposing
    ( AuditDiffCacheKey
    , AuditEvent
    , AuditEventKind(..)
    , AuditEventKindFilterTag(..)
    , AuditEventKindSummary(..)
    , AuditEventSummary
    , AuditLogFilter
    , Error(..)
    , EventDiffError(..)
    , HostAuditLogFilter
    , ScopedAuditEvent
    , ScopedAuditEventSummary
    , TrustedPublishAuditDiff(..)
    , allScopedEventsFromDict
    , append
    , auditDiffCacheKey
    , auditLogFilterCacheKey
    , emptyAuditLogFilter
    , emptyHostAuditLogFilter
    , errorToUserText
    , eventDiffErrorToUserText
    , eventKindFilterTagOptions
    , eventKindFilterTagToString
    , eventKindSummaryUserText
    , eventKindUserText
    , eventMatchesFilter
    , eventSummaryFromEvent
    , eventUtcTimestampStringFromSummary
    , eventUtcTimestampStringScopedSummary
    , filterEvents
    , filterScopedEvents
    , formatEventRowText
    , hostAuditDiffCacheKey
    , hostAuditLogFilterCacheKey
    , scopedEventMatchesFilter
    , scopedEventSummaryFromScoped
    , trustedPublishDiffFromKind
    )

import Dict exposing (Dict)
import Time
import Wiki


{-| Single append-only audit row for a wiki.
-}
type alias AuditEvent =
    { at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKind
    }


type AuditEventKind
    = ApprovedSubmission { submissionId : String, pageSlug : String }
    | ApprovedPublishedNewPage { submissionId : String, pageSlug : String }
    | ApprovedPublishedPageEdit { submissionId : String, pageSlug : String }
    | ApprovedPublishedPageDelete { submissionId : String, pageSlug : String }
    | RejectedSubmission { submissionId : String, pageSlug : String }
    | RequestedSubmissionChanges { submissionId : String, pageSlug : String }
    | PromotedContributorToTrusted { targetUsername : String }
    | DemotedTrustedToContributor { targetUsername : String }
    | GrantedWikiAdmin { targetUsername : String }
    | RevokedWikiAdmin { targetUsername : String }
    | TrustedPublishedNewPage { pageSlug : String, markdown : String }
    | TrustedPublishedPageEdit { pageSlug : String, beforeMarkdown : String, afterMarkdown : String }
    | TrustedPublishedPageDelete { pageSlug : String, reason : String }


{-| Selectable audit event categories for filtering.
-}
type AuditEventKindFilterTag
    = ApprovedSubmissionKind
    | ApprovedPublishedNewPageKind
    | ApprovedPublishedPageEditKind
    | ApprovedPublishedPageDeleteKind
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

        ApprovedPublishedNewPageKind ->
            "approved_published_new_page"

        ApprovedPublishedPageEditKind ->
            "approved_published_page_edit"

        ApprovedPublishedPageDeleteKind ->
            "approved_published_page_delete"

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
    [ ( ApprovedSubmissionKind, "Approved submission (legacy)" )
    , ( ApprovedPublishedNewPageKind, "Approved: new page" )
    , ( ApprovedPublishedPageEditKind, "Approved: edit" )
    , ( ApprovedPublishedPageDeleteKind, "Approved: delete" )
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

        ApprovedPublishedNewPage { pageSlug } ->
            Just pageSlug

        ApprovedPublishedPageEdit { pageSlug } ->
            Just pageSlug

        ApprovedPublishedPageDelete { pageSlug } ->
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


eventKindToSummary : AuditEventKind -> AuditEventKindSummary
eventKindToSummary kind =
    case kind of
        ApprovedSubmission r ->
            ApprovedSubmissionSummary r

        ApprovedPublishedNewPage r ->
            ApprovedPublishedNewPageSummary r

        ApprovedPublishedPageEdit r ->
            ApprovedPublishedPageEditSummary r

        ApprovedPublishedPageDelete r ->
            ApprovedPublishedPageDeleteSummary r

        RejectedSubmission r ->
            RejectedSubmissionSummary r

        RequestedSubmissionChanges r ->
            RequestedSubmissionChangesSummary r

        PromotedContributorToTrusted r ->
            PromotedContributorToTrustedSummary r

        DemotedTrustedToContributor r ->
            DemotedTrustedToContributorSummary r

        GrantedWikiAdmin r ->
            GrantedWikiAdminSummary r

        RevokedWikiAdmin r ->
            RevokedWikiAdminSummary r

        TrustedPublishedNewPage { pageSlug, markdown } ->
            TrustedPublishedNewPageSummary
                { pageSlug = pageSlug
                , markdownCharCount = String.length markdown
                }

        TrustedPublishedPageEdit { pageSlug, beforeMarkdown, afterMarkdown } ->
            TrustedPublishedPageEditSummary
                { pageSlug = pageSlug
                , beforeCharCount = String.length beforeMarkdown
                , afterCharCount = String.length afterMarkdown
                }

        TrustedPublishedPageDelete { pageSlug, reason } ->
            TrustedPublishedPageDeleteSummary { pageSlug = pageSlug, reason = reason }


eventSummaryFromEvent : AuditEvent -> AuditEventSummary
eventSummaryFromEvent e =
    { at = e.at
    , actorUsername = e.actorUsername
    , kind = eventKindToSummary e.kind
    }


scopedEventSummaryFromScoped : ScopedAuditEvent -> ScopedAuditEventSummary
scopedEventSummaryFromScoped e =
    { wikiSlug = e.wikiSlug
    , at = e.at
    , actorUsername = e.actorUsername
    , kind = eventKindToSummary e.kind
    }


trustedPublishDiffFromKind : AuditEventKind -> Maybe TrustedPublishAuditDiff
trustedPublishDiffFromKind kind =
    case kind of
        TrustedPublishedNewPage { pageSlug, markdown } ->
            Just (TrustedPublishNewPageDiff { pageSlug = pageSlug, markdown = markdown })

        TrustedPublishedPageEdit { pageSlug, beforeMarkdown, afterMarkdown } ->
            Just
                (TrustedPublishPageEditDiff
                    { pageSlug = pageSlug
                    , beforeMarkdown = beforeMarkdown
                    , afterMarkdown = afterMarkdown
                    }
                )

        ApprovedSubmission _ ->
            Nothing

        ApprovedPublishedNewPage _ ->
            Nothing

        ApprovedPublishedPageEdit _ ->
            Nothing

        ApprovedPublishedPageDelete _ ->
            Nothing

        RejectedSubmission _ ->
            Nothing

        RequestedSubmissionChanges _ ->
            Nothing

        PromotedContributorToTrusted _ ->
            Nothing

        DemotedTrustedToContributor _ ->
            Nothing

        GrantedWikiAdmin _ ->
            Nothing

        RevokedWikiAdmin _ ->
            Nothing

        TrustedPublishedPageDelete _ ->
            Nothing


kindMatchesFilterTag : AuditEventKind -> AuditEventKindFilterTag -> Bool
kindMatchesFilterTag kind tag =
    case ( kind, tag ) of
        ( ApprovedSubmission _, ApprovedSubmissionKind ) ->
            True

        ( ApprovedPublishedNewPage _, ApprovedPublishedNewPageKind ) ->
            True

        ( ApprovedPublishedPageEdit _, ApprovedPublishedPageEditKind ) ->
            True

        ( ApprovedPublishedPageDelete _, ApprovedPublishedPageDeleteKind ) ->
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


{-| Pure predicate for audit filtering.
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


{-| Audit row with wiki scope for the platform host-admin log (full cross-wiki view).
-}
type alias ScopedAuditEvent =
    { wikiSlug : Wiki.Slug
    , at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKind
    }


{-| [`AuditEventKind`](#AuditEventKind) without trusted-publish **markdown** (no before/after/new-page bodies).
List responses still carry small metadata: markdown character counts, edit before/after lengths, and delete reason text.
-}
type AuditEventKindSummary
    = ApprovedSubmissionSummary { submissionId : String, pageSlug : String }
    | ApprovedPublishedNewPageSummary { submissionId : String, pageSlug : String }
    | ApprovedPublishedPageEditSummary { submissionId : String, pageSlug : String }
    | ApprovedPublishedPageDeleteSummary { submissionId : String, pageSlug : String }
    | RejectedSubmissionSummary { submissionId : String, pageSlug : String }
    | RequestedSubmissionChangesSummary { submissionId : String, pageSlug : String }
    | PromotedContributorToTrustedSummary { targetUsername : String }
    | DemotedTrustedToContributorSummary { targetUsername : String }
    | GrantedWikiAdminSummary { targetUsername : String }
    | RevokedWikiAdminSummary { targetUsername : String }
    | TrustedPublishedNewPageSummary { pageSlug : String, markdownCharCount : Int }
    | TrustedPublishedPageEditSummary { pageSlug : String, beforeCharCount : Int, afterCharCount : Int }
    | TrustedPublishedPageDeleteSummary { pageSlug : String, reason : String }


{-| Metadata row for audit tables and list API payloads.
-}
type alias AuditEventSummary =
    { at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKindSummary
    }


{-| Scoped audit list item without trusted body payloads.
-}
type alias ScopedAuditEventSummary =
    { wikiSlug : Wiki.Slug
    , at : Time.Posix
    , actorUsername : String
    , kind : AuditEventKindSummary
    }


{-| Trusted direct-publish diff payload (fetched separately from list metadata).
-}
type TrustedPublishAuditDiff
    = TrustedPublishNewPageDiff { pageSlug : String, markdown : String }
    | TrustedPublishPageEditDiff { pageSlug : String, beforeMarkdown : String, afterMarkdown : String }


type EventDiffError
    = DiffWikiNotFound
    | DiffWikiInactive
    | DiffRowNotFound
    | DiffRowNotDiffable


type alias AuditDiffCacheKey =
    String


auditDiffCacheKey : Wiki.Slug -> AuditLogFilter -> Int -> AuditDiffCacheKey
auditDiffCacheKey wikiSlug filter rowIndex =
    wikiSlug
        ++ "\u{001E}"
        ++ auditLogFilterCacheKey filter
        ++ "\u{001E}"
        ++ String.fromInt rowIndex


hostAuditDiffCacheKey : HostAuditLogFilter -> Int -> AuditDiffCacheKey
hostAuditDiffCacheKey filter rowIndex =
    "host"
        ++ "\u{001E}"
        ++ hostAuditLogFilterCacheKey filter
        ++ "\u{001E}"
        ++ String.fromInt rowIndex


{-| Like [`AuditLogFilter`](#AuditLogFilter) plus optional wiki slug substring (case-insensitive).
-}
type alias HostAuditLogFilter =
    { wikiSlugSubstring : String
    , actorUsernameSubstring : String
    , pageSlugSubstring : String
    , eventKindTags : List AuditEventKindFilterTag
    }


emptyHostAuditLogFilter : HostAuditLogFilter
emptyHostAuditLogFilter =
    { wikiSlugSubstring = ""
    , actorUsernameSubstring = ""
    , pageSlugSubstring = ""
    , eventKindTags = []
    }


hostAuditLogFilterCacheKey : HostAuditLogFilter -> String
hostAuditLogFilterCacheKey f =
    let
        kindsPart : String
        kindsPart =
            f.eventKindTags
                |> List.map eventKindFilterTagToString
                |> List.sort
                |> String.join ","
    in
    String.toLower (String.trim f.wikiSlugSubstring)
        ++ "\u{001E}"
        ++ String.toLower (String.trim f.actorUsernameSubstring)
        ++ "\u{001E}"
        ++ String.toLower (String.trim f.pageSlugSubstring)
        ++ "\u{001E}"
        ++ kindsPart


scopedEventMatchesFilter : HostAuditLogFilter -> ScopedAuditEvent -> Bool
scopedEventMatchesFilter f ev =
    let
        wikiOk : Bool
        wikiOk =
            if String.isEmpty (String.trim f.wikiSlugSubstring) then
                True

            else
                String.contains
                    (String.toLower (String.trim f.wikiSlugSubstring))
                    (String.toLower ev.wikiSlug)

        coreFilter : AuditLogFilter
        coreFilter =
            { actorUsernameSubstring = f.actorUsernameSubstring
            , pageSlugSubstring = f.pageSlugSubstring
            , eventKindTags = f.eventKindTags
            }

        coreEvent : AuditEvent
        coreEvent =
            { at = ev.at
            , actorUsername = ev.actorUsername
            , kind = ev.kind
            }
    in
    wikiOk && eventMatchesFilter coreFilter coreEvent


filterScopedEvents : HostAuditLogFilter -> List ScopedAuditEvent -> List ScopedAuditEvent
filterScopedEvents f =
    List.filter (scopedEventMatchesFilter f)


{-| Flatten per-wiki audit lists into one stream ordered by time (oldest first).
-}
allScopedEventsFromDict : Dict Wiki.Slug (List AuditEvent) -> List ScopedAuditEvent
allScopedEventsFromDict dict =
    Dict.foldl
        (\wikiSlug events acc ->
            List.foldl
                (\e inner ->
                    { wikiSlug = wikiSlug
                    , at = e.at
                    , actorUsername = e.actorUsername
                    , kind = e.kind
                    }
                        :: inner
                )
                acc
                events
        )
        []
        dict
        |> List.sortBy (\e -> Time.posixToMillis e.at)


type Error
    = WikiNotFound
    | WikiInactive
    | Forbidden


errorToUserText : Error -> String
errorToUserText err =
    case err of
        WikiNotFound ->
            "This wiki was not found."

        WikiInactive ->
            "This wiki is currently paused."

        Forbidden ->
            "Only wiki admins can view the audit log."


{-| Append one event for a wiki (chronological: older events stay earlier in the list).
-}
append :
    Wiki.Slug
    -> Time.Posix
    -> String
    -> AuditEventKind
    -> Dict Wiki.Slug (List AuditEvent)
    -> Dict Wiki.Slug (List AuditEvent)
append wikiSlug at actorUsername kind dict =
    let
        ev : AuditEvent
        ev =
            { at = at
            , actorUsername = actorUsername
            , kind = kind
            }
    in
    Dict.update wikiSlug
        (\mv ->
            Just (Maybe.withDefault [] mv ++ [ ev ])
        )
        dict


{-| UTC wall time as `YYYY-MM-DD HH:mm:ss` (from [`elm/time`](https://package.elm-lang.org/packages/elm/time/latest/Time)).
-}
eventUtcTimestampString : AuditEvent -> String
eventUtcTimestampString e =
    posixUtcToYyyyMmDdHhMmSs e.at


posixUtcToYyyyMmDdHhMmSs : Time.Posix -> String
posixUtcToYyyyMmDdHhMmSs posix =
    let
        zone : Time.Zone
        zone =
            Time.utc

        pad2 : Int -> String
        pad2 n =
            n
                |> String.fromInt
                |> String.padLeft 2 '0'

        year : String
        year =
            Time.toYear zone posix
                |> String.fromInt
                |> String.padLeft 4 '0'
    in
    year
        ++ "-"
        ++ pad2 (monthToInt (Time.toMonth zone posix))
        ++ "-"
        ++ pad2 (Time.toDay zone posix)
        ++ " "
        ++ pad2 (Time.toHour zone posix)
        ++ ":"
        ++ pad2 (Time.toMinute zone posix)
        ++ ":"
        ++ pad2 (Time.toSecond zone posix)


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


eventKindUserText : AuditEventKind -> String
eventKindUserText kind =
    case kind of
        ApprovedSubmission { submissionId, pageSlug } ->
            "Approved submission "
                ++ submissionId
                ++ " (page "
                ++ pageSlug
                ++ ")"

        ApprovedPublishedNewPage { submissionId, pageSlug } ->
            "Approved new page "
                ++ pageSlug
                ++ " (submission "
                ++ submissionId
                ++ ")"

        ApprovedPublishedPageEdit { submissionId, pageSlug } ->
            "Approved edit to "
                ++ pageSlug
                ++ " (submission "
                ++ submissionId
                ++ ")"

        ApprovedPublishedPageDelete { submissionId, pageSlug } ->
            "Approved deletion of "
                ++ pageSlug
                ++ " (submission "
                ++ submissionId
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

        TrustedPublishedNewPage { pageSlug, markdown } ->
            "Trusted publish: created page "
                ++ pageSlug
                ++ " ("
                ++ String.fromInt (String.length markdown)
                ++ " chars)"

        TrustedPublishedPageEdit { pageSlug, beforeMarkdown, afterMarkdown } ->
            "Trusted publish: edited page "
                ++ pageSlug
                ++ " (before: "
                ++ String.fromInt (String.length beforeMarkdown)
                ++ " chars, after: "
                ++ String.fromInt (String.length afterMarkdown)
                ++ " chars"
                ++ ")"

        TrustedPublishedPageDelete { pageSlug, reason } ->
            "Trusted publish: deleted page "
                ++ pageSlug
                ++ (if String.isEmpty (String.trim reason) then
                        ""

                    else
                        " — " ++ String.trim reason
                   )


formatEventRowText : AuditEvent -> String
formatEventRowText e =
    eventUtcTimestampString e
        ++ " · "
        ++ e.actorUsername
        ++ " — "
        ++ eventKindUserText e.kind


eventUtcTimestampStringFromSummary : AuditEventSummary -> String
eventUtcTimestampStringFromSummary s =
    posixUtcToYyyyMmDdHhMmSs s.at


eventUtcTimestampStringScopedSummary : ScopedAuditEventSummary -> String
eventUtcTimestampStringScopedSummary e =
    eventUtcTimestampStringFromSummary
        { at = e.at
        , actorUsername = e.actorUsername
        , kind = e.kind
        }


eventKindSummaryUserText : AuditEventKindSummary -> String
eventKindSummaryUserText kind =
    case kind of
        ApprovedSubmissionSummary { submissionId, pageSlug } ->
            "Approved submission "
                ++ submissionId
                ++ " (page "
                ++ pageSlug
                ++ ")"

        ApprovedPublishedNewPageSummary { submissionId, pageSlug } ->
            "Approved new page "
                ++ pageSlug
                ++ " (submission "
                ++ submissionId
                ++ ")"

        ApprovedPublishedPageEditSummary { submissionId, pageSlug } ->
            "Approved edit to "
                ++ pageSlug
                ++ " (submission "
                ++ submissionId
                ++ ")"

        ApprovedPublishedPageDeleteSummary { submissionId, pageSlug } ->
            "Approved deletion of "
                ++ pageSlug
                ++ " (submission "
                ++ submissionId
                ++ ")"

        RejectedSubmissionSummary { submissionId, pageSlug } ->
            "Rejected submission "
                ++ submissionId
                ++ " (page "
                ++ pageSlug
                ++ ")"

        RequestedSubmissionChangesSummary { submissionId, pageSlug } ->
            "Requested changes on submission "
                ++ submissionId
                ++ " (page "
                ++ pageSlug
                ++ ")"

        PromotedContributorToTrustedSummary { targetUsername } ->
            "Promoted contributor " ++ targetUsername ++ " to trusted"

        DemotedTrustedToContributorSummary { targetUsername } ->
            "Demoted trusted contributor " ++ targetUsername ++ " to contributor"

        GrantedWikiAdminSummary { targetUsername } ->
            "Granted wiki admin to " ++ targetUsername

        RevokedWikiAdminSummary { targetUsername } ->
            "Revoked wiki admin from " ++ targetUsername

        TrustedPublishedNewPageSummary { pageSlug, markdownCharCount } ->
            "Trusted publish: created page "
                ++ pageSlug
                ++ " ("
                ++ String.fromInt markdownCharCount
                ++ " chars)"

        TrustedPublishedPageEditSummary { pageSlug, beforeCharCount, afterCharCount } ->
            "Trusted publish: edited page "
                ++ pageSlug
                ++ " (before: "
                ++ String.fromInt beforeCharCount
                ++ " chars, after: "
                ++ String.fromInt afterCharCount
                ++ " chars"
                ++ ")"

        TrustedPublishedPageDeleteSummary { pageSlug, reason } ->
            "Trusted publish: deleted page "
                ++ pageSlug
                ++ (if String.isEmpty (String.trim reason) then
                        ""

                    else
                        " — " ++ String.trim reason
                   )


eventDiffErrorToUserText : EventDiffError -> String
eventDiffErrorToUserText err =
    case err of
        DiffWikiNotFound ->
            "This wiki was not found."

        DiffWikiInactive ->
            "This wiki is currently paused."

        DiffRowNotFound ->
            "That audit row is not available (list may have changed)."

        DiffRowNotDiffable ->
            "Diff details are not available for this audit event."
