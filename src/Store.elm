module Store exposing
    ( Action(..)
    , Config
    , Store
    , Versioned
    , empty
    , get
    , getWikiAuditLog
    , getWikiStats
    , getWikiTodos
    , get_
    , perform
    , renameWikiSlug
    )

import CacheVersion
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
import WikiStats
import WikiTodos


{-| Client cache; survives route changes.
`wikiCatalog` tracks catalog fetch lifecycle.
-}
type alias Store =
    { wikiCatalog : RemoteData () (Dict Wiki.Slug Wiki.CatalogEntry)
    , wikiDetails : Dict Wiki.Slug (RemoteData () Wiki.FrontendDetails)
    , publishedPages : Dict ( Wiki.Slug, Page.Slug ) (RemoteData () Page.FrontendDetails)
    , reviewQueues :
        Dict Wiki.Slug (RemoteData () (Result Submission.ReviewQueueError (List Submission.ReviewQueueItem)))
    , myPendingSubmissions :
        Dict Wiki.Slug (RemoteData () (Result Submission.MyPendingSubmissionsError (List Submission.MyPendingSubmissionListItem)))
    , submissionDetails :
        Dict ( Wiki.Slug, String ) (RemoteData () (Result Submission.DetailsError Submission.ContributorView))
    , reviewSubmissionDetails :
        Dict ( Wiki.Slug, String ) (RemoteData () (Result SubmissionReviewDetail.ReviewSubmissionDetailError SubmissionReviewDetail.SubmissionReviewDetail))
    , wikiUsers :
        Dict Wiki.Slug (RemoteData () (Result WikiAdminUsers.Error (List WikiAdminUsers.ListedUser)))
    , wikiAuditLogs :
        Dict Wiki.Slug (Dict String (Versioned Int (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent))))
    , wikiTodos :
        Dict Wiki.Slug (Versioned Int (Result () (List WikiTodos.TableRow)))
    , wikiStats :
        Dict Wiki.Slug (Versioned CacheVersion.Versions (Maybe WikiStats.Summary))
    }


type alias Versioned version value =
    { version : version
    , value : RemoteData () value
    }


type Action
    = AskForWikiCatalog
    | AskForWikiFrontendDetails Wiki.Slug
    | AskForPageFrontendDetails Wiki.Slug Page.Slug
    | AskForMyPendingSubmissions Wiki.Slug
    | AskForReviewQueue Wiki.Slug
    | AskForReviewSubmissionDetail Wiki.Slug String
    | AskForWikiUsers Wiki.Slug
    | AskForWikiAuditLog Wiki.Slug WikiAuditLog.AuditLogFilter
    | RefreshWikiAuditLog Wiki.Slug WikiAuditLog.AuditLogFilter
    | AskForSubmissionDetails Wiki.Slug String
    | AskForWikiTodos Wiki.Slug
    | AskForWikiStats Wiki.Slug


empty : Store
empty =
    { wikiCatalog = NotAsked
    , wikiDetails = Dict.empty
    , publishedPages = Dict.empty
    , reviewQueues = Dict.empty
    , myPendingSubmissions = Dict.empty
    , submissionDetails = Dict.empty
    , reviewSubmissionDetails = Dict.empty
    , wikiUsers = Dict.empty
    , wikiAuditLogs = Dict.empty
    , wikiTodos = Dict.empty
    , wikiStats = Dict.empty
    }


type alias Config toBackend =
    { requestWikiCatalog : toBackend
    , requestWikiFrontendDetails : Wiki.Slug -> toBackend
    , requestPageFrontendDetails : Wiki.Slug -> Page.Slug -> toBackend
    , requestMyPendingSubmissions : Wiki.Slug -> toBackend
    , requestReviewQueue : Wiki.Slug -> toBackend
    , requestReviewSubmissionDetail : Wiki.Slug -> String -> toBackend
    , requestWikiUsers : Wiki.Slug -> toBackend
    , requestWikiAuditLog : Wiki.Slug -> WikiAuditLog.AuditLogFilter -> Maybe Int -> toBackend
    , requestSubmissionDetails : Wiki.Slug -> String -> toBackend
    , requestWikiTodos : Wiki.Slug -> Maybe Int -> toBackend
    , requestWikiStats : Wiki.Slug -> Maybe CacheVersion.Versions -> toBackend
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

        AskForWikiTodos wikiSlug ->
            let
                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    ( { store
                        | wikiTodos =
                            Dict.insert wikiSlug { version = 0, value = Loading } store.wikiTodos
                      }
                    , Effect.Lamdera.sendToBackend (config.requestWikiTodos wikiSlug Nothing)
                    )
            in
            case Dict.get wikiSlug store.wikiTodos of
                Just cached ->
                    case cached.value of
                        Success (Ok _) ->
                            ( store
                            , Effect.Lamdera.sendToBackend (config.requestWikiTodos wikiSlug (Just cached.version))
                            )

                        Success (Err _) ->
                            startLoad

                        Loading ->
                            ( store, Command.none )

                        Failure _ ->
                            startLoad

                        NotAsked ->
                            startLoad

                Nothing ->
                    startLoad

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

        AskForMyPendingSubmissions wikiSlug ->
            let
                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    ( { store
                        | myPendingSubmissions =
                            Dict.insert wikiSlug Loading store.myPendingSubmissions
                      }
                    , Effect.Lamdera.sendToBackend
                        (config.requestMyPendingSubmissions wikiSlug)
                    )
            in
            case Dict.get wikiSlug store.myPendingSubmissions |> join of
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

                inner0 : Dict String (Versioned Int (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                inner0 =
                    Dict.get wikiSlug store.wikiAuditLogs
                        |> Maybe.withDefault Dict.empty

                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    let
                        inner1 : Dict String (Versioned Int (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                        inner1 =
                            Dict.insert cacheKey { version = 0, value = Loading } inner0
                    in
                    ( { store
                        | wikiAuditLogs =
                            Dict.insert wikiSlug inner1 store.wikiAuditLogs
                      }
                    , Effect.Lamdera.sendToBackend (config.requestWikiAuditLog wikiSlug filter Nothing)
                    )
            in
            case Dict.get cacheKey inner0 of
                Just cached ->
                    case cached.value of
                        Success (Ok _) ->
                            ( store
                            , Effect.Lamdera.sendToBackend (config.requestWikiAuditLog wikiSlug filter (Just cached.version))
                            )

                        Success (Err _) ->
                            startLoad

                        Loading ->
                            ( store, Command.none )

                        Failure _ ->
                            startLoad

                        NotAsked ->
                            startLoad

                Nothing ->
                    startLoad

        RefreshWikiAuditLog wikiSlug filter ->
            let
                cacheKey : String
                cacheKey =
                    WikiAuditLog.auditLogFilterCacheKey filter

                inner0 : Dict String (Versioned Int (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                inner0 =
                    Dict.get wikiSlug store.wikiAuditLogs
                        |> Maybe.withDefault Dict.empty

                inner1 : Dict String (Versioned Int (Result WikiAuditLog.Error (List WikiAuditLog.AuditEvent)))
                inner1 =
                    Dict.insert cacheKey { version = 0, value = Loading } inner0
            in
            ( { store
                | wikiAuditLogs =
                    Dict.insert wikiSlug inner1 store.wikiAuditLogs
              }
            , Effect.Lamdera.sendToBackend (config.requestWikiAuditLog wikiSlug filter Nothing)
            )

        AskForWikiStats wikiSlug ->
            let
                startLoad : ( Store, Command FrontendOnly toBackend msg )
                startLoad =
                    ( { store
                        | wikiStats =
                            Dict.insert wikiSlug { version = CacheVersion.zero, value = Loading } store.wikiStats
                      }
                    , Effect.Lamdera.sendToBackend (config.requestWikiStats wikiSlug Nothing)
                    )
            in
            case Dict.get wikiSlug store.wikiStats of
                Just cached ->
                    case cached.value of
                        Loading ->
                            ( store, Command.none )

                        Success _ ->
                            ( store
                            , Effect.Lamdera.sendToBackend (config.requestWikiStats wikiSlug (Just cached.version))
                            )

                        Failure _ ->
                            startLoad

                        NotAsked ->
                            startLoad

                Nothing ->
                    startLoad


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

                Just cached ->
                    cached.value


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


getWikiStats : Wiki.Slug -> Store -> RemoteData () (Maybe WikiStats.Summary)
getWikiStats wikiSlug store =
    Dict.get wikiSlug store.wikiStats
        |> Maybe.map .value
        |> Maybe.withDefault NotAsked


getWikiTodos : Wiki.Slug -> Store -> RemoteData () (Result () (List WikiTodos.TableRow))
getWikiTodos wikiSlug store =
    Dict.get wikiSlug store.wikiTodos
        |> Maybe.map .value
        |> Maybe.withDefault NotAsked


renameWikiSlug : Wiki.Slug -> Wiki.Slug -> Store -> Store
renameWikiSlug oldSlug newSlug store =
    let
        remapDictKey : comparable -> comparable -> Dict comparable value -> Dict comparable value
        remapDictKey oldKey newKey dict =
            case Dict.get oldKey dict of
                Nothing ->
                    Dict.remove oldKey dict

                Just value ->
                    dict
                        |> Dict.remove oldKey
                        |> Dict.insert newKey value
    in
    { store
        | wikiDetails = remapDictKey oldSlug newSlug store.wikiDetails
        , publishedPages =
            store.publishedPages
                |> Dict.foldl
                    (\( wikiSlug, pageSlug ) value acc ->
                        if wikiSlug == oldSlug then
                            Dict.insert ( newSlug, pageSlug ) value acc

                        else
                            Dict.insert ( wikiSlug, pageSlug ) value acc
                    )
                    Dict.empty
        , reviewQueues = remapDictKey oldSlug newSlug store.reviewQueues
        , myPendingSubmissions = remapDictKey oldSlug newSlug store.myPendingSubmissions
        , submissionDetails =
            store.submissionDetails
                |> Dict.foldl
                    (\( wikiSlug, submissionId ) value acc ->
                        if wikiSlug == oldSlug then
                            Dict.insert ( newSlug, submissionId ) value acc

                        else
                            Dict.insert ( wikiSlug, submissionId ) value acc
                    )
                    Dict.empty
        , reviewSubmissionDetails =
            store.reviewSubmissionDetails
                |> Dict.foldl
                    (\( wikiSlug, submissionId ) value acc ->
                        if wikiSlug == oldSlug then
                            Dict.insert ( newSlug, submissionId ) value acc

                        else
                            Dict.insert ( wikiSlug, submissionId ) value acc
                    )
                    Dict.empty
        , wikiUsers = remapDictKey oldSlug newSlug store.wikiUsers
        , wikiAuditLogs = remapDictKey oldSlug newSlug store.wikiAuditLogs
        , wikiTodos = remapDictKey oldSlug newSlug store.wikiTodos
        , wikiStats = remapDictKey oldSlug newSlug store.wikiStats
    }


join : Maybe (RemoteData f b) -> RemoteData f b
join maybeRemoteData =
    case maybeRemoteData of
        Just remoteData ->
            remoteData

        Nothing ->
            NotAsked
