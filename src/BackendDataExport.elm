module BackendDataExport exposing
    ( ImportError
    , SnapshotFields
    , applySnapshotToBackendModel
    , applyWikiSnapshotMerge
    , decodeImportString
    , decodeWikiImportForSlug
    , encodeModelToJsonString
    , encodeWikiSnapshotToJsonString
    , importErrorToString
    , nextSubmissionCounterFromSubmissions
    )

import ContributorAccount
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Page
import Set exposing (Set)
import Submission
import Time
import Types exposing (BackendModel)
import Wiki exposing (Wiki)
import WikiAuditLog
import WikiContributors
import WikiRole
import WikiUser


formatId : String
formatId =
    "sortofwiki-backend-snapshot"


wikiSnapshotFormatId : String
wikiSnapshotFormatId =
    "sortofwiki-wiki-snapshot"


currentVersion : Int
currentVersion =
    1


{-| Payload restored from JSON (excludes host sessions; counter derived separately).
-}
type alias SnapshotFields =
    { wikis : Dict Wiki.Slug Wiki
    , contributors : WikiContributors.Registry
    , contributorSessions : WikiUser.SessionTable
    , submissions : Dict String Submission.Submission
    , wikiAuditEvents : Dict Wiki.Slug (List WikiAuditLog.AuditEvent)
    }


type ImportError
    = ImportJsonInvalid
    | ImportWrongFormat String
    | ImportUnsupportedVersion Int
    | ImportDecodeError String


importErrorToString : ImportError -> String
importErrorToString err =
    case err of
        ImportJsonInvalid ->
            "The file is not valid JSON."

        ImportWrongFormat detail ->
            "Unrecognized backup format: " ++ detail

        ImportUnsupportedVersion v ->
            "This backup is version "
                ++ String.fromInt v
                ++ ", which this server does not support."

        ImportDecodeError detail ->
            "Could not read backup data: " ++ detail


nextSubmissionCounterFromSubmissions : Dict String Submission.Submission -> Int
nextSubmissionCounterFromSubmissions subs =
    let
        parseSubNum : Submission.Id -> Maybe Int
        parseSubNum id =
            let
                s : String
                s =
                    Submission.idToString id
            in
            if String.startsWith "sub_" s then
                String.dropLeft 4 s
                    |> String.toInt

            else
                Nothing

        maxNum : Maybe Int
        maxNum =
            subs
                |> Dict.values
                |> List.filterMap (.id >> parseSubNum)
                |> List.maximum
    in
    Maybe.map (\n -> n + 1) maxNum
        |> Maybe.withDefault 1


encodeModelToJsonString : BackendModel -> String
encodeModelToJsonString model =
    Encode.encode 2
        (Encode.object
            [ ( "format", Encode.string formatId )
            , ( "version", Encode.int currentVersion )
            , ( "wikis", encodeWikis model.wikis )
            , ( "contributors", encodeContributors model.contributors )
            , ( "contributorSessions", Encode.object [] )
            , ( "submissions", encodeSubmissions model.submissions )
            , ( "wikiAuditEvents", encodeWikiAuditEvents model.wikiAuditEvents )
            ]
        )


applySnapshotToBackendModel : SnapshotFields -> Set String -> BackendModel
applySnapshotToBackendModel snapshot keptHostSessions =
    { wikis = snapshot.wikis
    , contributors = snapshot.contributors
    , contributorSessions = snapshot.contributorSessions
    , hostSessions = keptHostSessions
    , submissions = snapshot.submissions
    , nextSubmissionCounter = nextSubmissionCounterFromSubmissions snapshot.submissions
    , wikiAuditEvents = snapshot.wikiAuditEvents
    }


decodeImportString : String -> Result ImportError SnapshotFields
decodeImportString raw =
    case Decode.decodeString Decode.value raw of
        Err _ ->
            Err ImportJsonInvalid

        Ok val ->
            case Decode.decodeValue snapshotDecoder val of
                Ok snap ->
                    Ok snap

                Err e ->
                    case Decode.decodeValue (Decode.field "format" Decode.string) val of
                        Err _ ->
                            Err (ImportWrongFormat "missing or invalid format field")

                        Ok fmt ->
                            if fmt /= formatId then
                                Err (ImportWrongFormat ("expected format " ++ formatId))

                            else
                                case Decode.decodeValue (Decode.field "version" Decode.int) val of
                                    Ok v ->
                                        if v /= currentVersion then
                                            Err (ImportUnsupportedVersion v)

                                        else
                                            Err (ImportDecodeError (Decode.errorToString e))

                                    Err _ ->
                                        Err (ImportDecodeError (Decode.errorToString e))


snapshotDecoder : Decoder SnapshotFields
snapshotDecoder =
    Decode.field "format" Decode.string
        |> Decode.andThen
            (\fmt ->
                if fmt /= formatId then
                    Decode.fail ("wrong format: " ++ fmt)

                else
                    Decode.field "version" Decode.int
                        |> Decode.andThen
                            (\v ->
                                if v /= currentVersion then
                                    Decode.fail ("unsupported version " ++ String.fromInt v)

                                else
                                    Decode.map5 SnapshotFields
                                        (Decode.field "wikis" decodeWikis)
                                        (Decode.field "contributors" decodeContributors)
                                        decodeContributorSessionsImportIgnored
                                        (Decode.field "submissions" decodeSubmissions)
                                        (Decode.field "wikiAuditEvents" decodeWikiAuditEvents)
                            )
            )


encodeWikis : Dict Wiki.Slug Wiki -> Encode.Value
encodeWikis wikis =
    wikis
        |> Dict.toList
        |> List.map (\( slug, w ) -> ( slug, encodeWiki w ))
        |> Encode.object


encodeWiki : Wiki -> Encode.Value
encodeWiki w =
    Encode.object
        [ ( "slug", Encode.string w.slug )
        , ( "name", Encode.string w.name )
        , ( "summary", Encode.string w.summary )
        , ( "active", Encode.bool w.active )
        , ( "pages", encodePages w.pages )
        ]


encodePages : Dict Page.Slug Page.Page -> Encode.Value
encodePages pages =
    pages
        |> Dict.toList
        |> List.map (\( slug, p ) -> ( slug, encodePage p ))
        |> Encode.object


encodePage : Page.Page -> Encode.Value
encodePage p =
    Encode.object
        [ ( "slug", Encode.string p.slug )
        , ( "publishedMarkdown", encodeMaybeString p.publishedMarkdown )
        , ( "publishedRevision", Encode.int p.publishedRevision )
        , ( "pendingMarkdown", encodeMaybeString p.pendingMarkdown )
        ]


encodeMaybeString : Maybe String -> Encode.Value
encodeMaybeString m =
    case m of
        Nothing ->
            Encode.null

        Just s ->
            Encode.string s


decodeWikis : Decoder (Dict Wiki.Slug Wiki)
decodeWikis =
    Decode.dict decodeWiki


decodeWiki : Decoder Wiki
decodeWiki =
    Decode.map5 Wiki
        (Decode.field "slug" Decode.string)
        (Decode.field "name" Decode.string)
        (Decode.field "summary" Decode.string)
        (Decode.field "active" Decode.bool)
        (Decode.field "pages" decodePages)


decodePages : Decoder (Dict Page.Slug Page.Page)
decodePages =
    Decode.dict decodePage


decodePage : Decoder Page.Page
decodePage =
    Decode.map4 Page.Page
        (Decode.field "slug" Decode.string)
        (Decode.field "publishedMarkdown" (Decode.nullable Decode.string))
        (Decode.field "publishedRevision" Decode.int)
        (Decode.field "pendingMarkdown" (Decode.nullable Decode.string))


encodeContributors : WikiContributors.Registry -> Encode.Value
encodeContributors reg =
    reg
        |> Dict.toList
        |> List.map
            (\( wikiSlug, byUser ) ->
                ( wikiSlug
                , byUser
                    |> Dict.toList
                    |> List.map (\( u, stored ) -> ( u, encodeStoredContributor stored ))
                    |> Encode.object
                )
            )
        |> Encode.object


encodeStoredContributor : WikiContributors.StoredContributor -> Encode.Value
encodeStoredContributor sc =
    Encode.object
        [ ( "id", Encode.string (ContributorAccount.idToString sc.id) )
        , ( "passwordVerifierHex", Encode.string (ContributorAccount.verifierHexString sc.passwordVerifier) )
        , ( "role", Encode.string (WikiRole.backupTagEncode sc.role) )
        ]


decodeContributors : Decoder WikiContributors.Registry
decodeContributors =
    Decode.dict (Decode.dict decodeStoredContributor)


decodeStoredContributor : Decoder WikiContributors.StoredContributor
decodeStoredContributor =
    Decode.map3 WikiContributors.StoredContributor
        (Decode.field "id" ContributorAccount.idDecoder)
        (Decode.field "passwordVerifierHex" ContributorAccount.verifierDecoder)
        (Decode.field "role" WikiRole.backupTagDecoder)


decodeContributorSessionsImportIgnored : Decoder WikiUser.SessionTable
decodeContributorSessionsImportIgnored =
    Decode.oneOf
        [ Decode.field "contributorSessions" Decode.value |> Decode.map (\_ -> WikiUser.emptySessions)
        , Decode.succeed WikiUser.emptySessions
        ]


encodeSubmissions : Dict String Submission.Submission -> Encode.Value
encodeSubmissions subs =
    subs
        |> Dict.toList
        |> List.map (\( k, sub ) -> ( k, encodeSubmission sub ))
        |> Encode.object


encodeSubmission : Submission.Submission -> Encode.Value
encodeSubmission sub =
    Encode.object
        [ ( "id", Encode.string (Submission.idToString sub.id) )
        , ( "wikiSlug", Encode.string sub.wikiSlug )
        , ( "authorId", Encode.string (ContributorAccount.idToString sub.authorId) )
        , ( "kind", encodeSubmissionKind sub.kind )
        , ( "status", encodeSubmissionStatus sub.status )
        , ( "reviewerNote", encodeMaybeString sub.reviewerNote )
        ]


encodeSubmissionStatus : Submission.Status -> Encode.Value
encodeSubmissionStatus status =
    Encode.string
        (case status of
            Submission.Draft ->
                "draft"

            Submission.Pending ->
                "pending"

            Submission.Approved ->
                "approved"

            Submission.Rejected ->
                "rejected"

            Submission.NeedsRevision ->
                "needs_revision"
        )


encodeSubmissionKind : Submission.Kind -> Encode.Value
encodeSubmissionKind kind =
    case kind of
        Submission.NewPage body ->
            Encode.object
                [ ( "kind", Encode.string "new_page" )
                , ( "pageSlug", Encode.string body.pageSlug )
                , ( "markdown", Encode.string body.markdown )
                ]

        Submission.EditPage body ->
            Encode.object
                [ ( "kind", Encode.string "edit_page" )
                , ( "pageSlug", Encode.string body.pageSlug )
                , ( "baseMarkdown", Encode.string body.baseMarkdown )
                , ( "baseRevision", Encode.int body.baseRevision )
                , ( "proposedMarkdown", Encode.string body.proposedMarkdown )
                ]

        Submission.DeletePage body ->
            Encode.object
                [ ( "kind", Encode.string "delete_page" )
                , ( "pageSlug", Encode.string body.pageSlug )
                , ( "reason", encodeMaybeString body.reason )
                ]


decodeSubmissions : Decoder (Dict String Submission.Submission)
decodeSubmissions =
    Decode.dict decodeSubmission


decodeSubmission : Decoder Submission.Submission
decodeSubmission =
    Decode.map6 Submission.Submission
        (Decode.field "id" (Decode.map Submission.idFromKey Decode.string))
        (Decode.field "wikiSlug" Decode.string)
        (Decode.field "authorId" ContributorAccount.idDecoder)
        (Decode.field "kind" decodeSubmissionKind)
        (Decode.field "status" decodeSubmissionStatus)
        (Decode.field "reviewerNote" (Decode.nullable Decode.string))


decodeSubmissionStatus : Decoder Submission.Status
decodeSubmissionStatus =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "draft" ->
                        Decode.succeed Submission.Draft

                    "pending" ->
                        Decode.succeed Submission.Pending

                    "approved" ->
                        Decode.succeed Submission.Approved

                    "rejected" ->
                        Decode.succeed Submission.Rejected

                    "needs_revision" ->
                        Decode.succeed Submission.NeedsRevision

                    _ ->
                        Decode.fail ("unknown submission status: " ++ s)
            )


decodeSubmissionKind : Decoder Submission.Kind
decodeSubmissionKind =
    Decode.field "kind" Decode.string
        |> Decode.andThen decodeSubmissionKindFromTag


decodeSubmissionKindFromTag : String -> Decoder Submission.Kind
decodeSubmissionKindFromTag tag =
    case tag of
        "new_page" ->
            Decode.map2 Submission.NewPageBody
                (Decode.field "pageSlug" Decode.string)
                (Decode.field "markdown" Decode.string)
                |> Decode.map Submission.NewPage

        "edit_page" ->
            Decode.map4 Submission.EditPageBody
                (Decode.field "pageSlug" Decode.string)
                (Decode.field "baseMarkdown" Decode.string)
                (Decode.field "baseRevision" Decode.int)
                (Decode.field "proposedMarkdown" Decode.string)
                |> Decode.map Submission.EditPage

        "delete_page" ->
            Decode.map2 Submission.DeletePageBody
                (Decode.field "pageSlug" Decode.string)
                (Decode.field "reason" (Decode.nullable Decode.string))
                |> Decode.map Submission.DeletePage

        _ ->
            Decode.fail ("unknown submission kind: " ++ tag)


encodeWikiAuditEvents : Dict Wiki.Slug (List WikiAuditLog.AuditEvent) -> Encode.Value
encodeWikiAuditEvents evs =
    evs
        |> Dict.toList
        |> List.map
            (\( wikiSlug, rows ) ->
                ( wikiSlug, Encode.list encodeAuditEvent rows )
            )
        |> Encode.object


encodeAuditEvent : WikiAuditLog.AuditEvent -> Encode.Value
encodeAuditEvent ev =
    Encode.object
        [ ( "atMillis", Encode.int (Time.posixToMillis ev.at) )
        , ( "actorUsername", Encode.string ev.actorUsername )
        , ( "event", encodeAuditKind ev.kind )
        ]


encodeAuditKind : WikiAuditLog.AuditEventKind -> Encode.Value
encodeAuditKind kind =
    case kind of
        WikiAuditLog.ApprovedSubmission { submissionId, pageSlug } ->
            Encode.object
                [ ( "tag", Encode.string "approved_submission" )
                , ( "submissionId", Encode.string submissionId )
                , ( "pageSlug", Encode.string pageSlug )
                ]

        WikiAuditLog.RejectedSubmission { submissionId, pageSlug } ->
            Encode.object
                [ ( "tag", Encode.string "rejected_submission" )
                , ( "submissionId", Encode.string submissionId )
                , ( "pageSlug", Encode.string pageSlug )
                ]

        WikiAuditLog.RequestedSubmissionChanges { submissionId, pageSlug } ->
            Encode.object
                [ ( "tag", Encode.string "requested_submission_changes" )
                , ( "submissionId", Encode.string submissionId )
                , ( "pageSlug", Encode.string pageSlug )
                ]

        WikiAuditLog.PromotedContributorToTrusted { targetUsername } ->
            Encode.object
                [ ( "tag", Encode.string "promoted_contributor_to_trusted" )
                , ( "targetUsername", Encode.string targetUsername )
                ]

        WikiAuditLog.DemotedTrustedToContributor { targetUsername } ->
            Encode.object
                [ ( "tag", Encode.string "demoted_trusted_to_contributor" )
                , ( "targetUsername", Encode.string targetUsername )
                ]

        WikiAuditLog.GrantedWikiAdmin { targetUsername } ->
            Encode.object
                [ ( "tag", Encode.string "granted_wiki_admin" )
                , ( "targetUsername", Encode.string targetUsername )
                ]

        WikiAuditLog.RevokedWikiAdmin { targetUsername } ->
            Encode.object
                [ ( "tag", Encode.string "revoked_wiki_admin" )
                , ( "targetUsername", Encode.string targetUsername )
                ]

        WikiAuditLog.TrustedPublishedNewPage { pageSlug } ->
            Encode.object
                [ ( "tag", Encode.string "trusted_published_new_page" )
                , ( "pageSlug", Encode.string pageSlug )
                ]

        WikiAuditLog.TrustedPublishedPageEdit { pageSlug } ->
            Encode.object
                [ ( "tag", Encode.string "trusted_published_page_edit" )
                , ( "pageSlug", Encode.string pageSlug )
                ]

        WikiAuditLog.TrustedPublishedPageDelete { pageSlug, reason } ->
            Encode.object
                [ ( "tag", Encode.string "trusted_published_page_delete" )
                , ( "pageSlug", Encode.string pageSlug )
                , ( "reason", Encode.string reason )
                ]


decodeWikiAuditEvents : Decoder (Dict Wiki.Slug (List WikiAuditLog.AuditEvent))
decodeWikiAuditEvents =
    Decode.dict (Decode.list decodeAuditEvent)


decodeAuditEvent : Decoder WikiAuditLog.AuditEvent
decodeAuditEvent =
    Decode.map3 WikiAuditLog.AuditEvent
        (Decode.field "atMillis" (Decode.map Time.millisToPosix Decode.int))
        (Decode.field "actorUsername" Decode.string)
        (Decode.field "event" decodeAuditKind)


decodeAuditKind : Decoder WikiAuditLog.AuditEventKind
decodeAuditKind =
    Decode.field "tag" Decode.string
        |> Decode.andThen decodeAuditKindFromTag


decodeAuditKindFromTag : String -> Decoder WikiAuditLog.AuditEventKind
decodeAuditKindFromTag tag =
    case tag of
        "approved_submission" ->
            Decode.map2
                (\submissionId pageSlug ->
                    WikiAuditLog.ApprovedSubmission { submissionId = submissionId, pageSlug = pageSlug }
                )
                (Decode.field "submissionId" Decode.string)
                (Decode.field "pageSlug" Decode.string)

        "rejected_submission" ->
            Decode.map2
                (\submissionId pageSlug ->
                    WikiAuditLog.RejectedSubmission { submissionId = submissionId, pageSlug = pageSlug }
                )
                (Decode.field "submissionId" Decode.string)
                (Decode.field "pageSlug" Decode.string)

        "requested_submission_changes" ->
            Decode.map2
                (\submissionId pageSlug ->
                    WikiAuditLog.RequestedSubmissionChanges { submissionId = submissionId, pageSlug = pageSlug }
                )
                (Decode.field "submissionId" Decode.string)
                (Decode.field "pageSlug" Decode.string)

        "promoted_contributor_to_trusted" ->
            Decode.map (\u -> WikiAuditLog.PromotedContributorToTrusted { targetUsername = u })
                (Decode.field "targetUsername" Decode.string)

        "demoted_trusted_to_contributor" ->
            Decode.map (\u -> WikiAuditLog.DemotedTrustedToContributor { targetUsername = u })
                (Decode.field "targetUsername" Decode.string)

        "granted_wiki_admin" ->
            Decode.map (\u -> WikiAuditLog.GrantedWikiAdmin { targetUsername = u })
                (Decode.field "targetUsername" Decode.string)

        "revoked_wiki_admin" ->
            Decode.map (\u -> WikiAuditLog.RevokedWikiAdmin { targetUsername = u })
                (Decode.field "targetUsername" Decode.string)

        "trusted_published_new_page" ->
            Decode.map (\p -> WikiAuditLog.TrustedPublishedNewPage { pageSlug = p })
                (Decode.field "pageSlug" Decode.string)

        "trusted_published_page_edit" ->
            Decode.map (\p -> WikiAuditLog.TrustedPublishedPageEdit { pageSlug = p })
                (Decode.field "pageSlug" Decode.string)

        "trusted_published_page_delete" ->
            Decode.map2
                (\p r -> WikiAuditLog.TrustedPublishedPageDelete { pageSlug = p, reason = r })
                (Decode.field "pageSlug" Decode.string)
                (Decode.oneOf
                    [ Decode.field "reason" Decode.string
                    , Decode.succeed ""
                    ]
                )

        _ ->
            Decode.fail ("unknown audit event tag: " ++ tag)


{-| JSON for a single wiki (host admin per-wiki backup). Same inner schema as full snapshot with one wiki key.
-}
encodeWikiSnapshotToJsonString : Wiki.Slug -> BackendModel -> Maybe String
encodeWikiSnapshotToJsonString wikiSlug model =
    extractWikiSnapshotFields wikiSlug model
        |> Maybe.map
            (\snap ->
                Encode.encode 2 (encodeWikiSnapshotValue wikiSlug snap)
            )


encodeWikiSnapshotValue : Wiki.Slug -> SnapshotFields -> Encode.Value
encodeWikiSnapshotValue declaredSlug snap =
    Encode.object
        [ ( "format", Encode.string wikiSnapshotFormatId )
        , ( "version", Encode.int currentVersion )
        , ( "wikiSlug", Encode.string declaredSlug )
        , ( "wikis", encodeWikis snap.wikis )
        , ( "contributors", encodeContributors snap.contributors )
        , ( "contributorSessions", Encode.object [] )
        , ( "submissions", encodeSubmissions snap.submissions )
        , ( "wikiAuditEvents", encodeWikiAuditEvents snap.wikiAuditEvents )
        ]


extractWikiSnapshotFields : Wiki.Slug -> BackendModel -> Maybe SnapshotFields
extractWikiSnapshotFields wikiSlug model =
    case Dict.get wikiSlug model.wikis of
        Nothing ->
            Nothing

        Just wiki ->
            let
                byUser : Dict String WikiContributors.StoredContributor
                byUser =
                    model.contributors
                        |> Dict.get wikiSlug
                        |> Maybe.withDefault Dict.empty

                submissionsSlice : Dict String Submission.Submission
                submissionsSlice =
                    model.submissions
                        |> Dict.filter (\_ sub -> sub.wikiSlug == wikiSlug)

                auditRows : List WikiAuditLog.AuditEvent
                auditRows =
                    model.wikiAuditEvents
                        |> Dict.get wikiSlug
                        |> Maybe.withDefault []
            in
            Just
                { wikis = Dict.singleton wikiSlug wiki
                , contributors = Dict.singleton wikiSlug byUser
                , contributorSessions = WikiUser.emptySessions
                , submissions = submissionsSlice
                , wikiAuditEvents = Dict.singleton wikiSlug auditRows
                }


decodeWikiImportForSlug : Wiki.Slug -> String -> Result ImportError SnapshotFields
decodeWikiImportForSlug expectedSlug raw =
    case Decode.decodeString Decode.value raw of
        Err _ ->
            Err ImportJsonInvalid

        Ok val ->
            case Decode.decodeValue (wikiSnapshotFieldsDecoder expectedSlug) val of
                Ok snap ->
                    Ok snap

                Err e ->
                    case Decode.decodeValue (Decode.field "format" Decode.string) val of
                        Err _ ->
                            Err (ImportWrongFormat "missing or invalid format field")

                        Ok fmt ->
                            if fmt /= wikiSnapshotFormatId then
                                Err (ImportWrongFormat ("expected format " ++ wikiSnapshotFormatId))

                            else
                                case Decode.decodeValue (Decode.field "version" Decode.int) val of
                                    Ok v ->
                                        if v /= currentVersion then
                                            Err (ImportUnsupportedVersion v)

                                        else
                                            Err (ImportDecodeError (Decode.errorToString e))

                                    Err _ ->
                                        Err (ImportDecodeError (Decode.errorToString e))


wikiSnapshotFieldsDecoder : Wiki.Slug -> Decoder SnapshotFields
wikiSnapshotFieldsDecoder expectedSlug =
    Decode.field "format" Decode.string
        |> Decode.andThen
            (\fmt ->
                if fmt /= wikiSnapshotFormatId then
                    Decode.fail ("wrong format: " ++ fmt)

                else
                    Decode.field "version" Decode.int
                        |> Decode.andThen
                            (\v ->
                                if v /= currentVersion then
                                    Decode.fail ("unsupported version " ++ String.fromInt v)

                                else
                                    Decode.map2 Tuple.pair
                                        (Decode.field "wikiSlug" Decode.string)
                                        (Decode.map5 SnapshotFields
                                            (Decode.field "wikis" decodeWikis)
                                            (Decode.field "contributors" decodeContributors)
                                            decodeContributorSessionsImportIgnored
                                            (Decode.field "submissions" decodeSubmissions)
                                            (Decode.field "wikiAuditEvents" decodeWikiAuditEvents)
                                        )
                                        |> Decode.andThen
                                            (\( declaredSlug, snap ) ->
                                                if declaredSlug /= expectedSlug then
                                                    Decode.fail
                                                        "The file is for a different wiki slug than the row you imported from."

                                                else
                                                    case validateWikiSnapshotForSlug expectedSlug snap of
                                                        Err msg ->
                                                            Decode.fail msg

                                                        Ok () ->
                                                            Decode.succeed snap
                                            )
                            )
            )


validateWikiSnapshotForSlug : Wiki.Slug -> SnapshotFields -> Result String ()
validateWikiSnapshotForSlug expectedSlug snap =
    let
        wikiKeys : List Wiki.Slug
        wikiKeys =
            Dict.keys snap.wikis
    in
    if List.length wikiKeys /= 1 then
        Err "Wiki export must contain exactly one wiki."

    else
        case wikiKeys of
            [ onlySlug ] ->
                if onlySlug /= expectedSlug then
                    Err "Wiki data in the file does not match the selected wiki slug."

                else
                    let
                        contributorKeysOk : Bool
                        contributorKeysOk =
                            snap.contributors
                                |> Dict.keys
                                |> List.all (\k -> k == expectedSlug)
                    in
                    if not contributorKeysOk then
                        Err "Contributor data in the file references the wrong wiki slug."

                    else
                        let
                            auditKeysOk : Bool
                            auditKeysOk =
                                snap.wikiAuditEvents
                                    |> Dict.keys
                                    |> List.all (\k -> k == expectedSlug)
                        in
                        if not auditKeysOk then
                            Err "Audit data in the file references the wrong wiki slug."

                        else
                            let
                                submissionsOk : Bool
                                submissionsOk =
                                    snap.submissions
                                        |> Dict.values
                                        |> List.all (\sub -> sub.wikiSlug == expectedSlug)
                            in
                            if not submissionsOk then
                                Err "A submission in the file references the wrong wiki slug."

                            else
                                Ok ()

            _ ->
                Err "Wiki export must contain exactly one wiki."


{-| Replace one wiki slice on the backend. Submission ids are reassigned so imports never collide with other wikis.
-}
applyWikiSnapshotMerge : Wiki.Slug -> SnapshotFields -> BackendModel -> Result String BackendModel
applyWikiSnapshotMerge wikiSlug snap model =
    case validateWikiSnapshotForSlug wikiSlug snap of
        Err msg ->
            Err msg

        Ok () ->
            case Dict.get wikiSlug snap.wikis of
                Nothing ->
                    Err "Missing wiki payload after validation."

                Just wiki ->
                    let
                        ( remappedSubs, idMap, nextCounterAfterRemap ) =
                            remapWikiSubmissionsForImport model.nextSubmissionCounter snap.submissions

                        remappedAudit : List WikiAuditLog.AuditEvent
                        remappedAudit =
                            snap.wikiAuditEvents
                                |> Dict.get wikiSlug
                                |> Maybe.withDefault []
                                |> List.map (remapAuditEventSubmissionIds idMap)

                        contributorsForWiki : Dict String WikiContributors.StoredContributor
                        contributorsForWiki =
                            snap.contributors
                                |> Dict.get wikiSlug
                                |> Maybe.withDefault Dict.empty

                        submissionsWithoutWiki : Dict String Submission.Submission
                        submissionsWithoutWiki =
                            model.submissions
                                |> Dict.filter (\_ sub -> sub.wikiSlug /= wikiSlug)

                        mergedSubmissions : Dict String Submission.Submission
                        mergedSubmissions =
                            Dict.union remappedSubs submissionsWithoutWiki

                        nextCounter : Int
                        nextCounter =
                            max model.nextSubmissionCounter nextCounterAfterRemap
                                |> max (nextSubmissionCounterFromSubmissions mergedSubmissions)
                    in
                    Ok
                        { model
                            | wikis = Dict.insert wikiSlug wiki model.wikis
                            , contributors = Dict.insert wikiSlug contributorsForWiki model.contributors
                            , contributorSessions =
                                WikiUser.unionSessionOverlayPreferred snap.contributorSessions
                                    (WikiUser.dropBindingsForWiki wikiSlug model.contributorSessions)
                            , submissions = mergedSubmissions
                            , nextSubmissionCounter = nextCounter
                            , wikiAuditEvents = Dict.insert wikiSlug remappedAudit model.wikiAuditEvents
                        }


remapWikiSubmissionsForImport :
    Int
    -> Dict String Submission.Submission
    -> ( Dict String Submission.Submission, Dict String String, Int )
remapWikiSubmissionsForImport startCounter subs =
    subs
        |> Dict.values
        |> List.sortBy (\sub -> Submission.idToString sub.id)
        |> List.foldl
            (\sub ( c, idMap, acc ) ->
                let
                    oldKey : String
                    oldKey =
                        Submission.idToString sub.id

                    newId : Submission.Id
                    newId =
                        Submission.idFromCounter c

                    newKey : String
                    newKey =
                        Submission.idToString newId

                    nextSub : Submission.Submission
                    nextSub =
                        { sub | id = newId }
                in
                ( c + 1
                , Dict.insert oldKey newKey idMap
                , Dict.insert newKey nextSub acc
                )
            )
            ( startCounter, Dict.empty, Dict.empty )
        |> (\( c, idMap, acc ) -> ( acc, idMap, c ))


remapSubmissionWireId : Dict String String -> String -> String
remapSubmissionWireId idMap wireId =
    Dict.get wireId idMap
        |> Maybe.withDefault wireId


remapAuditEventSubmissionIds : Dict String String -> WikiAuditLog.AuditEvent -> WikiAuditLog.AuditEvent
remapAuditEventSubmissionIds idMap ev =
    { ev | kind = remapAuditKindSubmissionIds idMap ev.kind }


remapAuditKindSubmissionIds : Dict String String -> WikiAuditLog.AuditEventKind -> WikiAuditLog.AuditEventKind
remapAuditKindSubmissionIds idMap kind =
    case kind of
        WikiAuditLog.ApprovedSubmission r ->
            WikiAuditLog.ApprovedSubmission
                { r | submissionId = remapSubmissionWireId idMap r.submissionId }

        WikiAuditLog.RejectedSubmission r ->
            WikiAuditLog.RejectedSubmission
                { r | submissionId = remapSubmissionWireId idMap r.submissionId }

        WikiAuditLog.RequestedSubmissionChanges r ->
            WikiAuditLog.RequestedSubmissionChanges
                { r | submissionId = remapSubmissionWireId idMap r.submissionId }

        WikiAuditLog.PromotedContributorToTrusted r ->
            WikiAuditLog.PromotedContributorToTrusted r

        WikiAuditLog.DemotedTrustedToContributor r ->
            WikiAuditLog.DemotedTrustedToContributor r

        WikiAuditLog.GrantedWikiAdmin r ->
            WikiAuditLog.GrantedWikiAdmin r

        WikiAuditLog.RevokedWikiAdmin r ->
            WikiAuditLog.RevokedWikiAdmin r

        WikiAuditLog.TrustedPublishedNewPage r ->
            WikiAuditLog.TrustedPublishedNewPage r

        WikiAuditLog.TrustedPublishedPageEdit r ->
            WikiAuditLog.TrustedPublishedPageEdit r

        WikiAuditLog.TrustedPublishedPageDelete r ->
            WikiAuditLog.TrustedPublishedPageDelete r
