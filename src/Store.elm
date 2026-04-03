module Store exposing
    ( Action(..)
    , Config
    , Store
    , empty
    , get
    , getWikiAuditLog
    , get_
    , perform
    )

import Dict exposing (Dict)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Lamdera
import Page
import RemoteData exposing (RemoteData(..))
import Submission
import SubmissionReviewDetail
import Wiki
import WikiAdminUsers
import WikiAuditLog


{-| Client cache; survives route changes.
`wikiCatalog` tracks catalog fetch lifecycle.
-}
type alias Store =
    { wikiCatalog : RemoteData () (Dict Wiki.Slug Wiki.CatalogEntry)
    , wikiDetails : Dict Wiki.Slug (RemoteData () Wiki.FrontendDetails)
    , publishedPages : Dict ( Wiki.Slug, Page.Slug ) (RemoteData () Page.FrontendDetails)
    , reviewQueues :
        Dict Wiki.Slug (RemoteData () (Result Submission.ReviewQueueError (List Submission.ReviewQueueItem)))
    , submissionDetails :
        Dict ( Wiki.Slug, String ) (RemoteData () (Result Submission.DetailsError Submission.ContributorView))
    , reviewSubmissionDetails :
        Dict ( Wiki.Slug, String ) (RemoteData () (Result SubmissionReviewDetail.ReviewSubmissionDetailError SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers :
        Dict Wiki.Slug (RemoteData () (Result WikiAdminUsers.Error (List WikiAdminUsers.ListedUser)))
    , wikiAuditLogs :
        Dict Wiki.Slug (Dict String (RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent))))
    }


type Action
    = AskForWikiCatalog
    | AskForWikiFrontendDetails Wiki.Slug
    | AskForPageFrontendDetails Wiki.Slug Page.Slug
    | AskForReviewQueue Wiki.Slug
    | AskForReviewSubmissionDetail Wiki.Slug String
    | AskForWikiUsers Wiki.Slug
    | AskForWikiAuditLog Wiki.Slug WikiAuditLog.AuditLogFilter
    | RefreshWikiAuditLog Wiki.Slug WikiAuditLog.AuditLogFilter
    | AskForSubmissionDetails Wiki.Slug String


empty : Store
empty =
    { wikiCatalog = NotAsked
    , wikiDetails = Dict.empty
    , publishedPages = Dict.empty
    , reviewQueues = Dict.empty
    , submissionDetails = Dict.empty
    , reviewSubmissionDetails = Dict.empty
    , wikiUsers = Dict.empty
    , wikiAuditLogs = Dict.empty
    }


type alias Config toBackend =
    { requestWikiCatalog : toBackend
    , requestWikiFrontendDetails : Wiki.Slug -> toBackend
    , requestPageFrontendDetails : Wiki.Slug -> Page.Slug -> toBackend
    , requestReviewQueue : Wiki.Slug -> toBackend
    , requestReviewSubmissionDetail : Wiki.Slug -> String -> toBackend
    , requestWikiUsers : Wiki.Slug -> toBackend
    , requestWikiAuditLog : Wiki.Slug -> WikiAuditLog.AuditLogFilter -> toBackend
    , requestSubmissionDetails : Wiki.Slug -> String -> toBackend
    }


perform : Config toBackend -> Action -> Store -> ( Store, Command FrontendOnly toBackend msg )
perform config action store =
    case action of
        AskForWikiCatalog ->
            case store.wikiCatalog of
                Success _ ->
                    ( store, Command.none )

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    ( store, Command.none )

                NotAsked ->
                    ( { store | wikiCatalog = Loading }
                    , Effect.Lamdera.sendToBackend config.requestWikiCatalog
                    )

        AskForWikiFrontendDetails slug ->
            case Dict.get slug store.wikiDetails |> join of
                Success _ ->
                    ( store, Command.none )

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    ( store, Command.none )

                NotAsked ->
                    ( { store | wikiDetails = Dict.insert slug Loading store.wikiDetails }
                    , Effect.Lamdera.sendToBackend (config.requestWikiFrontendDetails slug)
                    )

        AskForPageFrontendDetails wikiSlug pageSlug ->
            let
                key : ( Wiki.Slug, Page.Slug )
                key =
                    ( wikiSlug, pageSlug )
            in
            case Dict.get key store.publishedPages |> join of
                Success _ ->
                    ( store, Command.none )

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    ( store, Command.none )

                NotAsked ->
                    ( { store
                        | publishedPages =
                            Dict.insert key Loading store.publishedPages
                      }
                    , Effect.Lamdera.sendToBackend
                        (config.requestPageFrontendDetails wikiSlug pageSlug)
                    )

        AskForReviewQueue wikiSlug ->
            let
                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    ( { store
                        | reviewQueues =
                            Dict.insert wikiSlug Loading store.reviewQueues
                      }
                    , Effect.Lamdera.sendToBackend
                        (config.requestReviewQueue wikiSlug)
                    )
            in
            case Dict.get wikiSlug store.reviewQueues |> join of
                Success (Ok _) ->
                    ( store, Command.none )

                Success (Err _) ->
                    startLoad

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    startLoad

                NotAsked ->
                    startLoad

        AskForSubmissionDetails wikiSlug submissionId ->
            let
                key : ( Wiki.Slug, String )
                key =
                    ( wikiSlug, submissionId )

                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    ( { store
                        | submissionDetails =
                            Dict.insert key Loading store.submissionDetails
                      }
                    , Effect.Lamdera.sendToBackend
                        (config.requestSubmissionDetails wikiSlug submissionId)
                    )
            in
            case Dict.get key store.submissionDetails |> join of
                Success (Ok _) ->
                    ( store, Command.none )

                Success (Err _) ->
                    startLoad

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    startLoad

                NotAsked ->
                    startLoad

        AskForReviewSubmissionDetail wikiSlug submissionId ->
            let
                key : ( Wiki.Slug, String )
                key =
                    ( wikiSlug, submissionId )

                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    ( { store
                        | reviewSubmissionDetails =
                            Dict.insert key Loading store.reviewSubmissionDetails
                      }
                    , Effect.Lamdera.sendToBackend
                        (config.requestReviewSubmissionDetail wikiSlug submissionId)
                    )
            in
            case Dict.get key store.reviewSubmissionDetails |> join of
                Success (Ok _) ->
                    ( store, Command.none )

                Success (Err _) ->
                    startLoad

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    startLoad

                NotAsked ->
                    startLoad

        AskForWikiUsers wikiSlug ->
            let
                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    ( { store
                        | wikiUsers =
                            Dict.insert wikiSlug Loading store.wikiUsers
                      }
                    , Effect.Lamdera.sendToBackend (config.requestWikiUsers wikiSlug)
                    )
            in
            case Dict.get wikiSlug store.wikiUsers |> join of
                Success (Ok _) ->
                    ( store, Command.none )

                Success (Err _) ->
                    startLoad

                Loading ->
                    ( store, Command.none )

                Failure _ ->
                    startLoad

                NotAsked ->
                    startLoad

        AskForWikiAuditLog wikiSlug filter ->
            let
                cacheKey : String
                cacheKey =
                    WikiAuditLog.auditLogFilterCacheKey filter

                inner0 : Dict String (RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                inner0 =
                    Dict.get wikiSlug store.wikiAuditLogs
                        |> Maybe.withDefault Dict.empty

                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    let
                        inner1 : Dict String (RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                        inner1 =
                            Dict.insert cacheKey Loading inner0
                    in
                    ( { store
                        | wikiAuditLogs =
                            Dict.insert wikiSlug inner1 store.wikiAuditLogs
                      }
                    , Effect.Lamdera.sendToBackend (config.requestWikiAuditLog wikiSlug filter)
                    )
            in
            case Dict.get cacheKey inner0 of
                Just (Success (Ok _)) ->
                    ( store, Command.none )

                Just (Success (Err _)) ->
                    startLoad

                Just Loading ->
                    ( store, Command.none )

                Just (Failure _) ->
                    startLoad

                Just NotAsked ->
                    startLoad

                Nothing ->
                    startLoad

        RefreshWikiAuditLog wikiSlug filter ->
            let
                cacheKey : String
                cacheKey =
                    WikiAuditLog.auditLogFilterCacheKey filter

                inner0 : Dict String (RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                inner0 =
                    Dict.get wikiSlug store.wikiAuditLogs
                        |> Maybe.withDefault Dict.empty

                inner1 : Dict String (RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                inner1 =
                    Dict.insert cacheKey Loading inner0
            in
            ( { store
                | wikiAuditLogs =
                    Dict.insert wikiSlug inner1 store.wikiAuditLogs
              }
            , Effect.Lamdera.sendToBackend (config.requestWikiAuditLog wikiSlug filter)
            )


getWikiAuditLog :
    Wiki.Slug
    -> WikiAuditLog.AuditLogFilter
    -> Store
    -> RemoteData () (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent))
getWikiAuditLog wikiSlug filter store =
    case Dict.get wikiSlug store.wikiAuditLogs of
        Nothing ->
            NotAsked

        Just inner ->
            case Dict.get (WikiAuditLog.auditLogFilterCacheKey filter) inner of
                Nothing ->
                    NotAsked

                Just remote ->
                    remote


get : comparable -> RemoteData f (Dict comparable b) -> RemoteData f b
get key remoteData =
    case remoteData of
        Success dict ->
            case Dict.get key dict of
                Nothing ->
                    NotAsked

                Just val ->
                    Success val

        Loading ->
            Loading

        NotAsked ->
            NotAsked

        Failure error ->
            Failure error


get_ : comparable -> Dict comparable (RemoteData f b) -> RemoteData f b
get_ key dict =
    case Dict.get key dict of
        Just remoteData ->
            remoteData

        Nothing ->
            NotAsked


join : Maybe (RemoteData f b) -> RemoteData f b
join maybeRemoteData =
    case maybeRemoteData of
        Just remoteData ->
            remoteData

        Nothing ->
            NotAsked
