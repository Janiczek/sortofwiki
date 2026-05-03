module Backend exposing (Model, Msg, app, app_, updateFromFrontendWithTime)

import BackendDataExport
import CacheVersion
import ContributorAccount
import ContributorWikiSession
import Dict exposing (Dict)
import Effect.Command as Command exposing (BackendOnly, Command)
import Effect.Lamdera exposing (ClientId, SessionId)
import Effect.Subscription as Subscription exposing (Subscription)
import Effect.Task
import Effect.Time
import Env
import HostAdmin
import Lamdera
import Page
import PendingReviewCount
import Set
import Submission
import SubmissionReviewDetail
import Time
import Types exposing (BackendModel, BackendMsg(..), ToBackend(..), ToFrontend(..), WikiStatsPartitions)
import Wiki exposing (Wiki)
import WikiAdminUsers
import WikiAuditLog
import WikiContributors
import WikiFrontendSubscription
import WikiRole
import WikiSearch
import WikiStats
import WikiTodos
import WikiUser


type alias Model =
    BackendModel


type alias Msg =
    BackendMsg


{-| Point wiki data, contributors, sessions, submissions, and audit log at `newSlug` (hosted wiki slug rename).
-}
applyHostedWikiSlugRename : Wiki.Slug -> Wiki.Slug -> Wiki -> Model -> Model
applyHostedWikiSlugRename oldSlug newSlug nextWiki model =
    let
        nextAudit : Dict Wiki.Slug (List WikiAuditLog.AuditEvent)
        nextAudit =
            case Dict.get oldSlug model.wikiAuditEvents of
                Nothing ->
                    Dict.remove oldSlug model.wikiAuditEvents

                Just events ->
                    model.wikiAuditEvents
                        |> Dict.remove oldSlug
                        |> Dict.insert newSlug events

        nextPageViewCounts : Dict Wiki.Slug (Dict Page.Slug Int)
        nextPageViewCounts =
            case Dict.get oldSlug model.pageViewCounts of
                Nothing ->
                    Dict.remove oldSlug model.pageViewCounts

                Just counts ->
                    model.pageViewCounts
                        |> Dict.remove oldSlug
                        |> Dict.insert newSlug counts

        nextAuditVersions : Dict Wiki.Slug Int
        nextAuditVersions =
            case Dict.get oldSlug model.wikiAuditVersions of
                Nothing ->
                    Dict.remove oldSlug model.wikiAuditVersions

                Just version ->
                    model.wikiAuditVersions
                        |> Dict.remove oldSlug
                        |> Dict.insert newSlug version

        nextViewsVersions : Dict Wiki.Slug Int
        nextViewsVersions =
            case Dict.get oldSlug model.wikiViewsVersions of
                Nothing ->
                    Dict.remove oldSlug model.wikiViewsVersions

                Just version ->
                    model.wikiViewsVersions
                        |> Dict.remove oldSlug
                        |> Dict.insert newSlug version
    in
    { model
        | wikis =
            model.wikis
                |> Dict.remove oldSlug
                |> Dict.insert newSlug nextWiki
        , contributors = WikiContributors.renameWikiSlug oldSlug newSlug model.contributors
        , contributorSessions = WikiUser.remapSessionsForWikiSlugRename oldSlug newSlug model.contributorSessions
        , submissions = Submission.remapWikiSlugInSubmissions oldSlug newSlug model.submissions
        , wikiAuditEvents = nextAudit
        , wikiAuditVersions = nextAuditVersions
        , pendingReviewCounts =
            PendingReviewCount.remapSlugInPendingCounts oldSlug newSlug model.pendingReviewCounts
        , pendingReviewClients =
            PendingReviewCount.remapSlugInPendingReviewClients oldSlug newSlug model.pendingReviewClients
        , wikiFrontendClients =
            WikiFrontendSubscription.remapSlugInWikiFrontendClients oldSlug newSlug model.wikiFrontendClients
        , wikiSearchIndexes =
            model.wikiSearchIndexes
                |> Dict.remove oldSlug
                |> Dict.insert newSlug (WikiSearch.buildPrefixIndex (Wiki.frontendDetails nextWiki).publishedPageMarkdownSources)
        , wikiTodosCaches =
            model.wikiTodosCaches
                |> Dict.remove oldSlug
                |> Dict.insert newSlug
                    (WikiTodos.tableRows newSlug (Wiki.frontendDetails nextWiki).publishedPageMarkdownSources)
        , pageViewCounts = nextPageViewCounts
        , wikiViewsVersions = nextViewsVersions
        , wikiStatsCache = Dict.remove oldSlug model.wikiStatsCache
    }


searchIndexForWiki : Wiki -> WikiSearch.PrefixIndex
searchIndexForWiki wiki =
    wiki
        |> Wiki.frontendDetails
        |> .publishedPageMarkdownSources
        |> WikiSearch.buildPrefixIndex


withWikiSearchIndex : Wiki.Slug -> Wiki -> Model -> Model
withWikiSearchIndex wikiSlug wiki model =
    { model
        | wikiSearchIndexes =
            Dict.insert wikiSlug (searchIndexForWiki wiki) model.wikiSearchIndexes
    }


withWikiTodosCache : Wiki.Slug -> Wiki -> Model -> Model
withWikiTodosCache wikiSlug wiki model =
    { model
        | wikiTodosCaches =
            Dict.insert wikiSlug
                (WikiTodos.tableRows wikiSlug (Wiki.frontendDetails wiki).publishedPageMarkdownSources)
                model.wikiTodosCaches
    }


withWikiSearchAndTodosCaches : Wiki.Slug -> Wiki -> Time.Posix -> Model -> Model
withWikiSearchAndTodosCaches wikiSlug wiki now model =
    model
        |> withWikiSearchIndex wikiSlug wiki
        |> withWikiTodosCache wikiSlug wiki
        |> withWikiStatsWikiCache wikiSlug wiki now


withRebuiltAllWikiSearchIndexes : Model -> Model
withRebuiltAllWikiSearchIndexes model =
    { model
        | wikiSearchIndexes =
            model.wikis
                |> Dict.map (\_ wiki -> searchIndexForWiki wiki)
    }


withRebuiltAllWikiTodosCaches : Model -> Model
withRebuiltAllWikiTodosCaches model =
    { model
        | wikiTodosCaches =
            model.wikis
                |> Dict.map (\slug wiki -> WikiTodos.tableRows slug (Wiki.frontendDetails wiki).publishedPageMarkdownSources)
    }


withRebuiltAllSearchAndTodosCaches : Time.Posix -> Model -> Model
withRebuiltAllSearchAndTodosCaches now model =
    model
        |> withRebuiltAllWikiSearchIndexes
        |> withRebuiltAllWikiTodosCaches
        |> withRebuiltAllWikiStatsCaches now


withWikiStatsWikiCache : Wiki.Slug -> Wiki -> Time.Posix -> Model -> Model
withWikiStatsWikiCache wikiSlug wiki now model =
    let
        auditEvents : List WikiAuditLog.AuditEvent
        auditEvents =
            Dict.get wikiSlug model.wikiAuditEvents
                |> Maybe.withDefault []

        fromWiki : WikiStats.FromWiki
        fromWiki =
            WikiStats.buildFromWiki wikiSlug wiki model.submissions auditEvents now

        partitions : WikiStatsPartitions
        partitions =
            case Dict.get wikiSlug model.wikiStatsCache of
                Just existing ->
                    { existing | fromWiki = fromWiki }

                Nothing ->
                    let
                        viewCounts : Dict Page.Slug Int
                        viewCounts =
                            Dict.get wikiSlug model.pageViewCounts
                                |> Maybe.withDefault Dict.empty
                    in
                    { fromWiki = fromWiki
                    , fromAudit = WikiStats.buildFromAudit now auditEvents
                    , fromViews = WikiStats.buildFromViews viewCounts
                    }
    in
    { model | wikiStatsCache = Dict.insert wikiSlug partitions model.wikiStatsCache }


withWikiStatsAuditCache : Wiki.Slug -> Time.Posix -> Model -> Model
withWikiStatsAuditCache wikiSlug now model =
    let
        auditEvents : List WikiAuditLog.AuditEvent
        auditEvents =
            Dict.get wikiSlug model.wikiAuditEvents
                |> Maybe.withDefault []

        fromAudit : WikiStats.FromAudit
        fromAudit =
            WikiStats.buildFromAudit now auditEvents

        partitions : WikiStatsPartitions
        partitions =
            case Dict.get wikiSlug model.wikiStatsCache of
                Just existing ->
                    let
                        fromWiki : WikiStats.FromWiki
                        fromWiki =
                            case Dict.get wikiSlug model.wikis of
                                Just wiki ->
                                    WikiStats.buildFromWiki wikiSlug wiki model.submissions auditEvents now

                                Nothing ->
                                    WikiStats.buildFromWiki wikiSlug (Wiki.wikiWithPages wikiSlug "" Dict.empty) model.submissions auditEvents now
                    in
                    { existing | fromAudit = fromAudit, fromWiki = fromWiki }

                Nothing ->
                    let
                        viewCounts : Dict Page.Slug Int
                        viewCounts =
                            Dict.get wikiSlug model.pageViewCounts
                                |> Maybe.withDefault Dict.empty

                        fromWiki : WikiStats.FromWiki
                        fromWiki =
                            case Dict.get wikiSlug model.wikis of
                                Just wiki ->
                                    WikiStats.buildFromWiki wikiSlug wiki model.submissions auditEvents now

                                Nothing ->
                                    WikiStats.buildFromWiki wikiSlug (Wiki.wikiWithPages wikiSlug "" Dict.empty) model.submissions auditEvents now
                    in
                    { fromWiki = fromWiki
                    , fromAudit = fromAudit
                    , fromViews = WikiStats.buildFromViews viewCounts
                    }
    in
    { model | wikiStatsCache = Dict.insert wikiSlug partitions model.wikiStatsCache }


withWikiStatsViewsCacheHit : Wiki.Slug -> Model -> Model
withWikiStatsViewsCacheHit wikiSlug model =
    case Dict.get wikiSlug model.wikiStatsCache of
        Just existing ->
            let
                viewCounts : Dict Page.Slug Int
                viewCounts =
                    Dict.get wikiSlug model.pageViewCounts
                        |> Maybe.withDefault Dict.empty

                fromViews : WikiStats.FromViews
                fromViews =
                    WikiStats.buildFromViews viewCounts

                partitions : WikiStatsPartitions
                partitions =
                    { existing | fromViews = fromViews }
            in
            { model | wikiStatsCache = Dict.insert wikiSlug partitions model.wikiStatsCache }

        Nothing ->
            model


withWikiStatsViewsCacheMiss : Wiki.Slug -> Time.Posix -> Model -> Model
withWikiStatsViewsCacheMiss wikiSlug now model =
    let
        viewCounts : Dict Page.Slug Int
        viewCounts =
            Dict.get wikiSlug model.pageViewCounts
                |> Maybe.withDefault Dict.empty

        fromViews : WikiStats.FromViews
        fromViews =
            WikiStats.buildFromViews viewCounts

        auditEvents : List WikiAuditLog.AuditEvent
        auditEvents =
            Dict.get wikiSlug model.wikiAuditEvents
                |> Maybe.withDefault []

        fromWiki : WikiStats.FromWiki
        fromWiki =
            case Dict.get wikiSlug model.wikis of
                Just wiki ->
                    WikiStats.buildFromWiki wikiSlug wiki model.submissions auditEvents now

                Nothing ->
                    WikiStats.buildFromWiki wikiSlug (Wiki.wikiWithPages wikiSlug "" Dict.empty) model.submissions auditEvents now

        partitions : WikiStatsPartitions
        partitions =
            { fromWiki = fromWiki
            , fromAudit = WikiStats.buildFromAudit now auditEvents
            , fromViews = fromViews
            }
    in
    { model | wikiStatsCache = Dict.insert wikiSlug partitions model.wikiStatsCache }


withRebuiltAllWikiStatsCaches : Time.Posix -> Model -> Model
withRebuiltAllWikiStatsCaches now model =
    let
        nextCache : Dict Wiki.Slug WikiStatsPartitions
        nextCache =
            model.wikis
                |> Dict.map
                    (\wikiSlug wiki ->
                        let
                            auditEvents : List WikiAuditLog.AuditEvent
                            auditEvents =
                                Dict.get wikiSlug model.wikiAuditEvents
                                    |> Maybe.withDefault []

                            viewCounts : Dict Page.Slug Int
                            viewCounts =
                                Dict.get wikiSlug model.pageViewCounts
                                    |> Maybe.withDefault Dict.empty
                        in
                        { fromWiki = WikiStats.buildFromWiki wikiSlug wiki model.submissions auditEvents now
                        , fromAudit = WikiStats.buildFromAudit now auditEvents
                        , fromViews = WikiStats.buildFromViews viewCounts
                        }
                    )
    in
    { model | wikiStatsCache = nextCache }


cacheVersionsForWiki : Wiki.Slug -> Model -> CacheVersion.Versions
cacheVersionsForWiki wikiSlug model =
    { contentVersion =
        model.wikis
            |> Dict.get wikiSlug
            |> Maybe.map .contentVersion
            |> Maybe.withDefault 0
    , auditVersion =
        Dict.get wikiSlug model.wikiAuditVersions
            |> Maybe.withDefault
                (model.wikiAuditEvents
                    |> Dict.get wikiSlug
                    |> Maybe.map List.length
                    |> Maybe.withDefault 0
                )
    , viewsVersion =
        Dict.get wikiSlug model.wikiViewsVersions
            |> Maybe.withDefault 0
    }


bumpAuditVersion : Wiki.Slug -> Model -> Model
bumpAuditVersion wikiSlug model =
    { model
        | wikiAuditVersions =
            Dict.update wikiSlug
                (\maybeVersion -> Just (Maybe.withDefault 0 maybeVersion + 1))
                model.wikiAuditVersions
    }


bumpViewsVersion : Wiki.Slug -> Model -> Model
bumpViewsVersion wikiSlug model =
    { model
        | wikiViewsVersions =
            Dict.update wikiSlug
                (\maybeVersion -> Just (Maybe.withDefault 0 maybeVersion + 1))
                model.wikiViewsVersions
    }


incrementPageView : Wiki.Slug -> Page.Slug -> Time.Posix -> Model -> Model
incrementPageView wikiSlug pageSlug now model =
    let
        wikiCounts : Dict Page.Slug Int
        wikiCounts =
            Dict.get wikiSlug model.pageViewCounts
                |> Maybe.withDefault Dict.empty

        newWikiCounts : Dict Page.Slug Int
        newWikiCounts =
            Dict.update pageSlug
                (\mv -> Just (Maybe.withDefault 0 mv + 1))
                wikiCounts

        pageViewUpdated : Model
        pageViewUpdated =
            { model | pageViewCounts = Dict.insert wikiSlug newWikiCounts model.pageViewCounts }
                |> bumpViewsVersion wikiSlug
    in
    case Dict.get wikiSlug pageViewUpdated.wikiStatsCache of
        Just _ ->
            withWikiStatsViewsCacheHit wikiSlug pageViewUpdated

        Nothing ->
            withWikiStatsViewsCacheMiss wikiSlug now pageViewUpdated


pendingCountForWiki : Wiki.Slug -> Model -> Int
pendingCountForWiki wikiSlug model =
    Dict.get wikiSlug model.pendingReviewCounts
        |> Maybe.withDefault (Submission.pendingReviewCountForWiki wikiSlug model.submissions)


withPendingMutation : Wiki.Slug -> Model -> Model
withPendingMutation wikiSlug model =
    let
        n : Int
        n =
            Submission.pendingReviewCountForWiki wikiSlug model.submissions
    in
    { model | pendingReviewCounts = Dict.insert wikiSlug n model.pendingReviewCounts }


withSubmissionMutation : Submission.Submission -> Maybe Submission.Submission -> Wiki.Slug -> Model -> Model
withSubmissionMutation prevSub nextSub wikiSlug model =
    let
        touched : Wiki.Slug -> Bool
        touched slug =
            if slug /= wikiSlug then
                False

            else
                let
                    nextTouchedPendingCount : Bool
                    nextTouchedPendingCount =
                        nextSub
                            |> Maybe.map Submission.statusTriggersPendingReviewCount
                            |> Maybe.withDefault False

                    submissionChanged : Bool
                    submissionChanged =
                        nextSub
                            |> Maybe.map (\sub -> prevSub /= sub)
                            |> Maybe.withDefault True
                in
                submissionChanged && (Submission.statusTriggersPendingReviewCount prevSub || nextTouchedPendingCount)
    in
    if touched wikiSlug then
        withPendingMutation wikiSlug model

    else
        model


sendPendingReviewCountToTrustedSubscribers : Wiki.Slug -> Model -> Command BackendOnly ToFrontend Msg
sendPendingReviewCountToTrustedSubscribers wikiSlug model =
    let
        count : Int
        count =
            pendingCountForWiki wikiSlug model

        msg : ToFrontend
        msg =
            PendingReviewCountUpdated wikiSlug count
    in
    PendingReviewCount.listenerClientIdsForWiki wikiSlug model.pendingReviewClients
        |> List.map (\cid -> Effect.Lamdera.sendToFrontend cid msg)
        |> Command.batch


refreshTrustedListenerWikiFrontendDetails :
    Wiki.Slug
    -> Model
    -> List String
    -> Command BackendOnly ToFrontend Msg
refreshTrustedListenerWikiFrontendDetails wikiSlug model sessionKeys =
    let
        listenersBySession : Dict String (Set.Set String)
        listenersBySession =
            WikiFrontendSubscription.listenerSessionsForWiki wikiSlug model.wikiFrontendClients
    in
    sessionKeys
        |> List.map
            (\sessionKey ->
                listenersBySession
                    |> Dict.get sessionKey
                    |> Maybe.map
                        (\clientIds ->
                            clientIds
                                |> Set.toList
                                |> List.map
                                    (\targetClientId ->
                                        Effect.Lamdera.sendToFrontend
                                            (Effect.Lamdera.clientIdFromString targetClientId)
                                            (WikiFrontendDetailsResponse wikiSlug
                                                (wikiFrontendDetailsPayloadForSession wikiSlug sessionKey model)
                                            )
                                    )
                                |> Command.batch
                        )
                    |> Maybe.withDefault Command.none
            )
        |> Command.batch


evictContributorPendingReviewListeners : Wiki.Slug -> ContributorAccount.Id -> Model -> Model
evictContributorPendingReviewListeners wikiSlug accountId model =
    let
        nextClients : PendingReviewCount.PendingReviewClientSets
        nextClients =
            WikiUser.sessionKeysForContributorOnWiki wikiSlug accountId model.contributorSessions
                |> List.foldl
                    (\sessionKey acc ->
                        PendingReviewCount.evictSessionFromWikiListeners wikiSlug sessionKey acc
                    )
                    model.pendingReviewClients
    in
    { model | pendingReviewClients = nextClients }


wikiFrontendDetailsPayloadForSession :
    Wiki.Slug
    -> String
    -> Model
    -> Maybe Wiki.FrontendDetails
wikiFrontendDetailsPayloadForSession slug sessionKey model =
    model.wikis
        |> Dict.get slug
        |> Maybe.andThen
            (\w ->
                if w.active then
                    case WikiUser.sessionContributorOnWiki sessionKey slug model.contributorSessions of
                        WikiUser.SessionHasAccount accountId ->
                            let
                                viewerSession : Maybe ContributorWikiSession.ContributorWikiSession
                                viewerSession =
                                    Maybe.map2
                                        (\displayUsername role ->
                                            { role = role
                                            , displayUsername = displayUsername
                                            }
                                        )
                                        (WikiContributors.displayUsernameForAccount slug accountId model.contributors)
                                        (WikiContributors.roleForAccount slug accountId model.contributors)

                                maybeTrustedCount : Maybe Int
                                maybeTrustedCount =
                                    Just (pendingCountForWiki slug model)
                            in
                            Just
                                (Wiki.frontendDetailsForViewer w
                                    viewerSession
                                    maybeTrustedCount
                                )

                        _ ->
                            Just (Wiki.frontendDetailsForViewer w Nothing Nothing)

                else
                    Nothing
            )


{-| Append one audit row at `now`.
Uses the acting account id (moderator / admin), not submission authors.
-}
recordAudit : Time.Posix -> Wiki.Slug -> ContributorAccount.Id -> WikiAuditLog.AuditEventKind -> Model -> Model
recordAudit now wikiSlug actorId kind model =
    let
        actor : String
        actor =
            WikiContributors.displayUsernameForAccount wikiSlug actorId model.contributors
                |> Maybe.withDefault "unknown"

        nextModel : Model
        nextModel =
            { model
                | wikiAuditEvents =
                    WikiAuditLog.append wikiSlug now actor kind model.wikiAuditEvents
            }
    in
    withWikiStatsAuditCache wikiSlug now nextModel
        |> bumpAuditVersion wikiSlug


{-| Push fresh `Wiki.frontendDetails` so all clients keep tag maps and link sources aligned after publish/delete.
-}
broadcastWikiFrontendDetails : Wiki.Slug -> Model -> Command BackendOnly ToFrontend Msg
broadcastWikiFrontendDetails wikiSlug model =
    WikiFrontendSubscription.listenerSessionsForWiki wikiSlug model.wikiFrontendClients
        |> Dict.toList
        |> List.map
            (\( sessionKey, clientIds ) ->
                clientIds
                    |> Set.toList
                    |> List.map
                        (\targetClientId ->
                            Effect.Lamdera.sendToFrontend
                                (Effect.Lamdera.clientIdFromString targetClientId)
                                (WikiFrontendDetailsResponse wikiSlug
                                    (wikiFrontendDetailsPayloadForSession wikiSlug sessionKey model)
                                )
                        )
                    |> Command.batch
            )
        |> Command.batch


broadcastWikiCacheInvalidated : Wiki.Slug -> Model -> Command BackendOnly ToFrontend Msg
broadcastWikiCacheInvalidated wikiSlug model =
    let
        msg : ToFrontend
        msg =
            WikiCacheInvalidated wikiSlug (cacheVersionsForWiki wikiSlug model)
    in
    WikiFrontendSubscription.listenerSessionsForWiki wikiSlug model.wikiFrontendClients
        |> Dict.values
        |> List.concatMap Set.toList
        |> List.map
            (\targetClientId ->
                Effect.Lamdera.sendToFrontend
                    (Effect.Lamdera.clientIdFromString targetClientId)
                    msg
            )
        |> Command.batch


broadcastWikiCatalog : Model -> Command BackendOnly ToFrontend Msg
broadcastWikiCatalog model =
    Effect.Lamdera.broadcast (WikiCatalogResponse (Wiki.publicCatalogDict model.wikis))


broadcastWikiSlugRenamed : Wiki.Slug -> Wiki.Slug -> Model -> Command BackendOnly ToFrontend Msg
broadcastWikiSlugRenamed oldSlug newSlug model =
    let
        msg : ToFrontend
        msg =
            WikiSlugRenamed oldSlug newSlug
    in
    WikiFrontendSubscription.listenerSessionsForWiki newSlug model.wikiFrontendClients
        |> Dict.values
        |> List.concatMap Set.toList
        |> List.map
            (\targetClientId ->
                Effect.Lamdera.sendToFrontend
                    (Effect.Lamdera.clientIdFromString targetClientId)
                    msg
            )
        |> Command.batch


init : ( Model, Command BackendOnly ToFrontend Msg )
init =
    ( { wikis = Dict.empty
      , contributors = WikiContributors.emptyRegistry
      , contributorSessions = WikiUser.emptySessions
      , hostSessions = Set.empty
      , submissions = Dict.empty
      , nextSubmissionCounter = 1
      , wikiAuditEvents = Dict.empty
      , wikiAuditVersions = Dict.empty
      , pendingReviewCounts = PendingReviewCount.emptyCountMap
      , pendingReviewClients = PendingReviewCount.emptyClientSets
      , wikiFrontendClients = WikiFrontendSubscription.emptyClientSets
      , wikiSearchIndexes = Dict.empty
      , wikiTodosCaches = Dict.empty
      , pageViewCounts = Dict.empty
      , wikiViewsVersions = Dict.empty
      , wikiStatsCache = Dict.empty
      }
    , Command.none
    )


update : Msg -> Model -> ( Model, Command BackendOnly ToFrontend Msg )
update msg model =
    case msg of
        ToBackendGotTime sessionId clientId wrapped now ->
            updateFromFrontendWithTime sessionId clientId wrapped now model


{-| Client messages from Lamdera.

**Authorization:** privileged handlers consult `contributorSessions` and `hostSessions`
(and wiki binding) before changing state. Regression coverage: `tests/BackendAuthorizationTest.elm`
(per-message `Err` and no mutation where applicable; see program tests for backend authorization).

**Public:** `RequestWikiCatalog`, `RequestWikiFrontendDetails`, `RequestWikiTodos`, `RequestPageFrontendDetails`.
**Credential setup:** `RegisterContributor`, `LoginContributor`, `LogoutContributor`, `HostAdminLogin`.

Each `ToBackend` is handled after `Effect.Time.now` resolves (see `ToBackendGotTime`).

-}
updateFromFrontend :
    SessionId
    -> ClientId
    -> ToBackend
    -> Model
    -> ( Model, Command BackendOnly ToFrontend Msg )
updateFromFrontend sessionId clientId msg model =
    ( model
    , Effect.Task.perform (ToBackendGotTime sessionId clientId msg) Effect.Time.now
    )


{-| Handle `ToBackend` with a known time (tests and `ToBackendGotTime`).
-}
updateFromFrontendWithTime :
    SessionId
    -> ClientId
    -> ToBackend
    -> Time.Posix
    -> Model
    -> ( Model, Command BackendOnly ToFrontend Msg )
updateFromFrontendWithTime sessionId clientId msg now model =
    case msg of
        RequestWikiCatalog ->
            ( model
            , Effect.Lamdera.sendToFrontend clientId
                (WikiCatalogResponse (Wiki.publicCatalogDict model.wikis))
            )

        RequestWikiFrontendDetails slug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                wikiFrontendClientsNext : WikiFrontendSubscription.WikiFrontendClientSets
                wikiFrontendClientsNext =
                    WikiFrontendSubscription.subscribeViewer slug sessionKey clientId model.wikiFrontendClients

                pendingClientsNext : PendingReviewCount.PendingReviewClientSets
                pendingClientsNext =
                    case WikiUser.sessionContributorOnWiki sessionKey slug model.contributorSessions of
                        WikiUser.SessionHasAccount accountId ->
                            if WikiContributors.isTrustedForWiki slug accountId model.contributors then
                                PendingReviewCount.subscribeTrustedViewer slug sessionKey clientId model.pendingReviewClients

                            else
                                PendingReviewCount.evictSessionFromWikiListeners slug sessionKey model.pendingReviewClients

                        _ ->
                            PendingReviewCount.evictSessionFromWikiListeners slug sessionKey model.pendingReviewClients

                modelForResponse : Model
                modelForResponse =
                    { model
                        | pendingReviewClients = pendingClientsNext
                        , wikiFrontendClients = wikiFrontendClientsNext
                    }

                payload : Maybe Wiki.FrontendDetails
                payload =
                    wikiFrontendDetailsPayloadForSession slug sessionKey modelForResponse
            in
            ( modelForResponse
            , Effect.Lamdera.sendToFrontend clientId (WikiFrontendDetailsResponse slug payload)
            )

        RequestWikiTodos slug maybeKnownVersion ->
            let
                respond : Model -> List WikiTodos.TableRow -> ( Model, Command BackendOnly ToFrontend Msg )
                respond m rows =
                    ( m
                    , Effect.Lamdera.sendToFrontend clientId (WikiTodosResponse slug (cacheVersionsForWiki slug m).contentVersion (Ok rows))
                    )
            in
            case Dict.get slug model.wikis of
                Nothing ->
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (WikiTodosResponse slug 0 (Err ()))
                    )

                Just wiki ->
                    if not wiki.active then
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId (WikiTodosResponse slug wiki.contentVersion (Err ()))
                        )

                    else if maybeKnownVersion == Just wiki.contentVersion then
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId WikiTodosUnchanged
                        )

                    else
                        case Dict.get slug model.wikiTodosCaches of
                            Just rows ->
                                respond model rows

                            Nothing ->
                                let
                                    rows : List WikiTodos.TableRow
                                    rows =
                                        WikiTodos.tableRows slug (Wiki.frontendDetails wiki).publishedPageMarkdownSources

                                    nextModel : Model
                                    nextModel =
                                        { model
                                            | wikiTodosCaches = Dict.insert slug rows model.wikiTodosCaches
                                        }
                                in
                                respond nextModel rows

        RequestPageFrontendDetails wikiSlug pageSlug ->
            let
                maybeDetails : Maybe Page.FrontendDetails
                maybeDetails =
                    model.wikis
                        |> Dict.get wikiSlug
                        |> Maybe.andThen
                            (\w ->
                                if w.active then
                                    Wiki.publishedPageFrontendDetails pageSlug w

                                else
                                    Nothing
                            )

                nextModel : Model
                nextModel =
                    case maybeDetails of
                        Just _ ->
                            incrementPageView wikiSlug pageSlug now model

                        Nothing ->
                            model
            in
            ( nextModel
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId
                    (PageFrontendDetailsResponse wikiSlug pageSlug maybeDetails)
                , case maybeDetails of
                    Just _ ->
                        broadcastWikiCacheInvalidated wikiSlug nextModel

                    Nothing ->
                        Command.none
                ]
            )

        RequestWikiStats wikiSlug maybeKnownVersions ->
            let
                versions : CacheVersion.Versions
                versions =
                    cacheVersionsForWiki wikiSlug model

                maybeSummary : Maybe WikiStats.Summary
                maybeSummary =
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            Nothing

                        Just wiki ->
                            if not wiki.active then
                                Nothing

                            else
                                let
                                    partitions : WikiStatsPartitions
                                    partitions =
                                        case Dict.get wikiSlug model.wikiStatsCache of
                                            Just cached ->
                                                cached

                                            Nothing ->
                                                let
                                                    auditEvents : List WikiAuditLog.AuditEvent
                                                    auditEvents =
                                                        Dict.get wikiSlug model.wikiAuditEvents
                                                            |> Maybe.withDefault []

                                                    viewCounts : Dict Page.Slug Int
                                                    viewCounts =
                                                        Dict.get wikiSlug model.pageViewCounts
                                                            |> Maybe.withDefault Dict.empty
                                                in
                                                { fromWiki = WikiStats.buildFromWiki wikiSlug wiki model.submissions auditEvents now
                                                , fromAudit = WikiStats.buildFromAudit now auditEvents
                                                , fromViews = WikiStats.buildFromViews viewCounts
                                                }
                                in
                                Just (WikiStats.merge partitions.fromWiki partitions.fromAudit partitions.fromViews)
            in
            case maybeKnownVersions of
                Just knownVersions ->
                    if CacheVersion.same knownVersions versions then
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId WikiStatsUnchanged
                        )

                    else
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId (WikiStatsResponse wikiSlug versions maybeSummary)
                        )

                Nothing ->
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (WikiStatsResponse wikiSlug versions maybeSummary)
                    )

        RequestWikiSearch wikiSlug rawQuery ->
            let
                query : String
                query =
                    String.trim rawQuery

                ( modelForSearch, prefixIndex ) =
                    case Dict.get wikiSlug model.wikiSearchIndexes of
                        Just index ->
                            ( model, index )

                        Nothing ->
                            case Dict.get wikiSlug model.wikis of
                                Just wiki ->
                                    if wiki.active then
                                        let
                                            index : WikiSearch.PrefixIndex
                                            index =
                                                searchIndexForWiki wiki
                                        in
                                        ( { model
                                            | wikiSearchIndexes =
                                                Dict.insert wikiSlug index model.wikiSearchIndexes
                                          }
                                        , index
                                        )

                                    else
                                        ( model, Dict.empty )

                                Nothing ->
                                    ( model, Dict.empty )

                results : List WikiSearch.ResultItem
                results =
                    if String.isEmpty query then
                        []

                    else
                        WikiSearch.searchWithPrefixIndex query prefixIndex
            in
            ( modelForSearch
            , Effect.Lamdera.sendToFrontend clientId
                (WikiSearchResponse wikiSlug query results)
            )

        RequestReviewQueue wikiSlug ->
            let
                respond : Result Submission.ReviewQueueError (List Submission.ReviewQueueItem) -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ReviewQueueResponse wikiSlug res)
                    )

                lookupAuthor : ContributorAccount.Id -> Maybe String
                lookupAuthor accountId =
                    WikiContributors.displayUsernameForAccount wikiSlug accountId model.contributors

                wikiPaused : Bool
                wikiPaused =
                    Dict.get wikiSlug model.wikis
                        |> Maybe.map (not << .active)
                        |> Maybe.withDefault False
            in
            if wikiPaused then
                respond (Err Submission.ReviewQueueWikiInactive)

            else
                let
                    sessionKey : String
                    sessionKey =
                        Effect.Lamdera.sessionIdToString sessionId
                in
                case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                    WikiUser.SessionNotLoggedIn ->
                        respond (Err Submission.ReviewQueueNotLoggedIn)

                    WikiUser.SessionWrongWiki ->
                        respond (Err Submission.ReviewQueueWrongWikiSession)

                    WikiUser.SessionHasAccount accountId ->
                        if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                            respond (Err Submission.ReviewQueueForbidden)

                        else
                            model.submissions
                                |> Submission.pendingSubmissionsForWiki wikiSlug
                                |> List.map (Submission.reviewQueueItemFromSubmission lookupAuthor)
                                |> Ok
                                |> respond

        RequestMyPendingSubmissions wikiSlug ->
            let
                respond : Result Submission.MyPendingSubmissionsError (List Submission.MyPendingSubmissionListItem) -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (MyPendingSubmissionsResponse wikiSlug res)
                    )

                wikiPaused : Bool
                wikiPaused =
                    Dict.get wikiSlug model.wikis
                        |> Maybe.map (not << .active)
                        |> Maybe.withDefault False
            in
            if wikiPaused then
                respond (Err Submission.MyPendingSubmissionsWikiInactive)

            else
                let
                    sessionKey : String
                    sessionKey =
                        Effect.Lamdera.sessionIdToString sessionId
                in
                case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                    WikiUser.SessionNotLoggedIn ->
                        respond (Err Submission.MyPendingSubmissionsNotLoggedIn)

                    WikiUser.SessionWrongWiki ->
                        respond (Err Submission.MyPendingSubmissionsWrongWikiSession)

                    WikiUser.SessionHasAccount accountId ->
                        if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                            respond (Err Submission.MyPendingSubmissionsForbiddenTrustedModerator)

                        else
                            model.submissions
                                |> Submission.mySubmissionsForAuthorOnWiki wikiSlug accountId
                                |> List.map Submission.myPendingSubmissionListItemFromSubmission
                                |> Ok
                                |> respond

        RequestWikiUsers wikiSlug ->
            let
                respond : Result WikiAdminUsers.Error (List WikiAdminUsers.ListedUser) -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (WikiUsersResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.WikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.WikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.NotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.WrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.Forbidden)

                                else
                                    WikiContributors.usersForWikiListing wikiSlug model.contributors
                                        |> Ok
                                        |> respond

        RequestWikiAuditLog wikiSlug filter maybeKnownVersion ->
            let
                version : Int
                version =
                    (cacheVersionsForWiki wikiSlug model).auditVersion

                respond : Result WikiAuditLog.Error (List WikiAuditLog.AuditEventSummary) -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (WikiAuditLogResponse wikiSlug filter version res)
                    )
            in
            if maybeKnownVersion == Just version then
                ( model
                , Effect.Lamdera.sendToFrontend clientId (WikiAuditLogUnchanged wikiSlug)
                )

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respond (Err WikiAuditLog.WikiNotFound)

                    Just w ->
                        if not w.active then
                            respond (Err WikiAuditLog.WikiInactive)

                        else
                            model.wikiAuditEvents
                                |> Dict.get wikiSlug
                                |> Maybe.withDefault []
                                |> WikiAuditLog.filterEvents filter
                                |> List.map WikiAuditLog.eventSummaryFromEvent
                                |> Ok
                                |> respond

        RequestWikiAuditEventDiff wikiSlug filter rowIndex ->
            let
                respondDiff : Result WikiAuditLog.EventDiffError WikiAuditLog.TrustedPublishAuditDiff -> ( Model, Command BackendOnly ToFrontend Msg )
                respondDiff res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (WikiAuditEventDiffResponse wikiSlug filter rowIndex res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respondDiff (Err WikiAuditLog.DiffWikiNotFound)

                Just w ->
                    if not w.active then
                        respondDiff (Err WikiAuditLog.DiffWikiInactive)

                    else
                        let
                            events : List WikiAuditLog.AuditEvent
                            events =
                                model.wikiAuditEvents
                                    |> Dict.get wikiSlug
                                    |> Maybe.withDefault []
                                    |> WikiAuditLog.filterEvents filter
                        in
                        case List.drop rowIndex events of
                            [] ->
                                respondDiff (Err WikiAuditLog.DiffRowNotFound)

                            ev :: _ ->
                                case WikiAuditLog.trustedPublishDiffFromKind ev.kind of
                                    Nothing ->
                                        respondDiff (Err WikiAuditLog.DiffRowNotDiffable)

                                    Just body ->
                                        respondDiff (Ok body)

        PromoteContributorToTrusted wikiSlug rawTargetUsername ->
            let
                respond :
                    Result WikiAdminUsers.PromoteContributorError ()
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (PromoteContributorToTrustedResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.PromoteWikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.PromoteWikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.PromoteNotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.PromoteWrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.PromoteForbidden)

                                else
                                    let
                                        normalizedTarget : String
                                        normalizedTarget =
                                            ContributorAccount.normalizeUsername rawTargetUsername
                                    in
                                    if String.isEmpty normalizedTarget then
                                        respond (Err WikiAdminUsers.PromoteTargetNotFound)

                                    else
                                        case WikiContributors.promoteContributorToTrustedAtWiki wikiSlug normalizedTarget model.contributors of
                                            Err e ->
                                                respond (Err e)

                                            Ok nextContributors ->
                                                let
                                                    promotedAccountIdMaybe : Maybe ContributorAccount.Id
                                                    promotedAccountIdMaybe =
                                                        WikiContributors.contributorAccountIdForNormalizedUsername wikiSlug normalizedTarget nextContributors

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model | contributors = nextContributors }

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit now
                                                            wikiSlug
                                                            accountId
                                                            (WikiAuditLog.PromotedContributorToTrusted { targetUsername = normalizedTarget })
                                                            nextModel0

                                                    promotedSessionKeys : List String
                                                    promotedSessionKeys =
                                                        promotedAccountIdMaybe
                                                            |> Maybe.map (\tid -> WikiUser.sessionKeysForContributorOnWiki wikiSlug tid model.contributorSessions)
                                                            |> Maybe.withDefault []
                                                in
                                                ( nextModel
                                                , Command.batch
                                                    [ Effect.Lamdera.sendToFrontend clientId
                                                        (PromoteContributorToTrustedResponse wikiSlug (Ok ()))
                                                    , refreshTrustedListenerWikiFrontendDetails wikiSlug nextModel promotedSessionKeys
                                                    , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                    ]
                                                )

        DemoteTrustedToContributor wikiSlug rawTargetUsername ->
            let
                respond :
                    Result WikiAdminUsers.DemoteTrustedError ()
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DemoteTrustedToContributorResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.DemoteWikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.DemoteWikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.DemoteNotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.DemoteWrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.DemoteForbidden)

                                else
                                    let
                                        normalizedTarget : String
                                        normalizedTarget =
                                            ContributorAccount.normalizeUsername rawTargetUsername
                                    in
                                    if String.isEmpty normalizedTarget then
                                        respond (Err WikiAdminUsers.DemoteTargetNotFound)

                                    else
                                        case WikiContributors.demoteTrustedToContributorAtWiki wikiSlug normalizedTarget model.contributors of
                                            Err e ->
                                                respond (Err e)

                                            Ok nextContributors ->
                                                let
                                                    demotedAccountIdMaybe : Maybe ContributorAccount.Id
                                                    demotedAccountIdMaybe =
                                                        WikiContributors.contributorAccountIdForNormalizedUsername wikiSlug normalizedTarget nextContributors

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model | contributors = nextContributors }

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit now
                                                            wikiSlug
                                                            accountId
                                                            (WikiAuditLog.DemotedTrustedToContributor { targetUsername = normalizedTarget })
                                                            nextModel0

                                                    nextModelEvicted : Model
                                                    nextModelEvicted =
                                                        demotedAccountIdMaybe
                                                            |> Maybe.map (\tid -> evictContributorPendingReviewListeners wikiSlug tid nextModel)
                                                            |> Maybe.withDefault nextModel

                                                    refreshSessions : List String
                                                    refreshSessions =
                                                        demotedAccountIdMaybe
                                                            |> Maybe.map (\tid -> WikiUser.sessionKeysForContributorOnWiki wikiSlug tid model.contributorSessions)
                                                            |> Maybe.withDefault []
                                                in
                                                ( nextModelEvicted
                                                , Command.batch
                                                    [ Effect.Lamdera.sendToFrontend clientId
                                                        (DemoteTrustedToContributorResponse wikiSlug (Ok ()))
                                                    , refreshTrustedListenerWikiFrontendDetails wikiSlug nextModelEvicted refreshSessions
                                                    , broadcastWikiCacheInvalidated wikiSlug nextModelEvicted
                                                    ]
                                                )

        GrantWikiAdmin wikiSlug rawTargetUsername ->
            let
                respond :
                    Result WikiAdminUsers.GrantTrustedToAdminError ()
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (GrantWikiAdminResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.GrantTrustedWikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.GrantTrustedWikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.GrantTrustedNotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.GrantTrustedWrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.GrantTrustedForbidden)

                                else
                                    let
                                        normalizedTarget : String
                                        normalizedTarget =
                                            ContributorAccount.normalizeUsername rawTargetUsername
                                    in
                                    if String.isEmpty normalizedTarget then
                                        respond (Err WikiAdminUsers.GrantTrustedTargetNotFound)

                                    else
                                        case WikiContributors.grantTrustedToAdminAtWiki wikiSlug normalizedTarget model.contributors of
                                            Err e ->
                                                respond (Err e)

                                            Ok nextContributors ->
                                                let
                                                    targetAccountIdMaybe : Maybe ContributorAccount.Id
                                                    targetAccountIdMaybe =
                                                        WikiContributors.contributorAccountIdForNormalizedUsername wikiSlug normalizedTarget nextContributors

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model | contributors = nextContributors }

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit now
                                                            wikiSlug
                                                            accountId
                                                            (WikiAuditLog.GrantedWikiAdmin { targetUsername = normalizedTarget })
                                                            nextModel0

                                                    refreshSessions : List String
                                                    refreshSessions =
                                                        targetAccountIdMaybe
                                                            |> Maybe.map (\tid -> WikiUser.sessionKeysForContributorOnWiki wikiSlug tid model.contributorSessions)
                                                            |> Maybe.withDefault []
                                                in
                                                ( nextModel
                                                , Command.batch
                                                    [ Effect.Lamdera.sendToFrontend clientId
                                                        (GrantWikiAdminResponse wikiSlug (Ok ()))
                                                    , refreshTrustedListenerWikiFrontendDetails wikiSlug nextModel refreshSessions
                                                    , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                    ]
                                                )

        RevokeWikiAdmin wikiSlug rawTargetUsername ->
            let
                respond :
                    Result WikiAdminUsers.RevokeAdminError ()
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RevokeWikiAdminResponse wikiSlug res)
                    )
            in
            case Dict.get wikiSlug model.wikis of
                Nothing ->
                    respond (Err WikiAdminUsers.RevokeAdminWikiNotFound)

                Just w ->
                    if not w.active then
                        respond (Err WikiAdminUsers.RevokeAdminWikiInactive)

                    else
                        let
                            sessionKey : String
                            sessionKey =
                                Effect.Lamdera.sessionIdToString sessionId
                        in
                        case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                            WikiUser.SessionNotLoggedIn ->
                                respond (Err WikiAdminUsers.RevokeAdminNotLoggedIn)

                            WikiUser.SessionWrongWiki ->
                                respond (Err WikiAdminUsers.RevokeAdminWrongWikiSession)

                            WikiUser.SessionHasAccount accountId ->
                                if not (WikiContributors.isAdminForWiki wikiSlug accountId model.contributors) then
                                    respond (Err WikiAdminUsers.RevokeAdminForbidden)

                                else
                                    let
                                        normalizedTarget : String
                                        normalizedTarget =
                                            ContributorAccount.normalizeUsername rawTargetUsername
                                    in
                                    if String.isEmpty normalizedTarget then
                                        respond (Err WikiAdminUsers.RevokeAdminTargetNotFound)

                                    else
                                        case WikiContributors.revokeAdminToTrustedAtWiki wikiSlug accountId normalizedTarget model.contributors of
                                            Err e ->
                                                respond (Err e)

                                            Ok nextContributors ->
                                                let
                                                    targetAccountIdMaybe : Maybe ContributorAccount.Id
                                                    targetAccountIdMaybe =
                                                        WikiContributors.contributorAccountIdForNormalizedUsername wikiSlug normalizedTarget nextContributors

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model | contributors = nextContributors }

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit now
                                                            wikiSlug
                                                            accountId
                                                            (WikiAuditLog.RevokedWikiAdmin { targetUsername = normalizedTarget })
                                                            nextModel0

                                                    refreshSessions : List String
                                                    refreshSessions =
                                                        targetAccountIdMaybe
                                                            |> Maybe.map (\tid -> WikiUser.sessionKeysForContributorOnWiki wikiSlug tid model.contributorSessions)
                                                            |> Maybe.withDefault []
                                                in
                                                ( nextModel
                                                , Command.batch
                                                    [ Effect.Lamdera.sendToFrontend clientId
                                                        (RevokeWikiAdminResponse wikiSlug (Ok ()))
                                                    , refreshTrustedListenerWikiFrontendDetails wikiSlug nextModel refreshSessions
                                                    , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                    ]
                                                )

        RequestReviewSubmissionDetail wikiSlug submissionId ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond :
                    Result SubmissionReviewDetail.ReviewSubmissionDetailError SubmissionReviewDetail.SubmissionReviewDetail
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ReviewSubmissionDetailResponse wikiSlug submissionId res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err SubmissionReviewDetail.ReviewSubmissionDetailWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respond (Err SubmissionReviewDetail.ReviewSubmissionDetailForbidden)

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotFound)

                            Just wiki ->
                                if not wiki.active then
                                    respond (Err SubmissionReviewDetail.ReviewSubmissionDetailWikiInactive)

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotFound)

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respond (Err SubmissionReviewDetail.ReviewSubmissionDetailNotFound)

                                            else
                                                respond
                                                    (Ok (SubmissionReviewDetail.reviewDetailFromWikiAndSubmission wiki sub))

        RequestSubmissionDetails wikiSlug submissionId ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.DetailsError Submission.ContributorView -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmissionDetailsResponse wikiSlug submissionId res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.DetailsNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.DetailsWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    let
                        submissionBranch : ( Model, Command BackendOnly ToFrontend Msg )
                        submissionBranch =
                            case Dict.get submissionId model.submissions of
                                Nothing ->
                                    respond (Err Submission.DetailsNotFound)

                                Just sub ->
                                    if sub.wikiSlug /= wikiSlug then
                                        respond (Err Submission.DetailsNotFound)

                                    else if sub.authorId /= accountId then
                                        respond (Err Submission.DetailsForbidden)

                                    else
                                        respond (Ok (Submission.contributorViewFromSubmission (Dict.get wikiSlug model.wikis) sub))
                    in
                    case Dict.get wikiSlug model.wikis of
                        Just w ->
                            if not w.active then
                                respond (Err Submission.DetailsWikiInactive)

                            else
                                submissionBranch

                        Nothing ->
                            submissionBranch

        RegisterContributor wikiSlug cred ->
            case WikiContributors.attemptRegister wikiSlug cred.username cred.password model.wikis model.contributors of
                Err err ->
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RegisterContributorResponse wikiSlug (Err err))
                    )

                Ok ( nextContributors, accountId ) ->
                    let
                        sessionKey : String
                        sessionKey =
                            Effect.Lamdera.sessionIdToString sessionId

                        nextSessions : WikiUser.SessionTable
                        nextSessions =
                            WikiUser.bindContributor sessionKey wikiSlug accountId model.contributorSessions
                    in
                    ( { model
                        | contributors = nextContributors
                        , contributorSessions = nextSessions
                      }
                    , Effect.Lamdera.sendToFrontend clientId
                        (RegisterContributorResponse wikiSlug (Ok (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)))
                    )

        LoginContributor wikiSlug cred ->
            case WikiContributors.attemptLogin wikiSlug cred.username cred.password model.wikis model.contributors of
                Err err ->
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (LoginContributorResponse wikiSlug (Err err))
                    )

                Ok accountId ->
                    let
                        sessionKey : String
                        sessionKey =
                            Effect.Lamdera.sessionIdToString sessionId

                        nextSessions : WikiUser.SessionTable
                        nextSessions =
                            WikiUser.bindContributor sessionKey wikiSlug accountId model.contributorSessions

                        role : WikiRole.WikiRole
                        role =
                            WikiContributors.roleForAccount wikiSlug accountId model.contributors
                                |> Maybe.withDefault (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)

                        nextModel : Model
                        nextModel =
                            { model | contributorSessions = nextSessions }

                        trustedRefreshCmd : Command BackendOnly ToFrontend Msg
                        trustedRefreshCmd =
                            if WikiContributors.isTrustedForWiki wikiSlug accountId nextModel.contributors then
                                refreshTrustedListenerWikiFrontendDetails wikiSlug nextModel [ sessionKey ]

                            else
                                Command.none
                    in
                    ( nextModel
                    , Command.batch
                        [ Effect.Lamdera.sendToFrontend clientId (LoginContributorResponse wikiSlug (Ok role))
                        , trustedRefreshCmd
                        ]
                    )

        LogoutContributor wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                wikiSlugsToRefresh : List Wiki.Slug
                wikiSlugsToRefresh =
                    WikiFrontendSubscription.wikiSlugsListeningForSession sessionKey model.wikiFrontendClients

                nextSessions : WikiUser.SessionTable
                nextSessions =
                    WikiUser.unbindContributor sessionKey wikiSlug model.contributorSessions

                pendingClientsNext : PendingReviewCount.PendingReviewClientSets
                pendingClientsNext =
                    PendingReviewCount.evictSessionFromWikiListeners wikiSlug sessionKey model.pendingReviewClients

                nextModel : Model
                nextModel =
                    { model
                        | contributorSessions = nextSessions
                        , pendingReviewClients = pendingClientsNext
                    }

                logoutRefreshCmd : Command BackendOnly ToFrontend Msg
                logoutRefreshCmd =
                    wikiSlugsToRefresh
                        |> List.map
                            (\slug ->
                                refreshTrustedListenerWikiFrontendDetails slug nextModel [ sessionKey ]
                            )
                        |> Command.batch
            in
            ( nextModel
            , Command.batch
                [ Effect.Lamdera.sendToFrontend clientId (LogoutContributorResponse wikiSlug)
                , logoutRefreshCmd
                ]
            )

        SubmitNewPage wikiSlug body ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.SubmitNewPageError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmitNewPageResponse wikiSlug (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.NotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.WrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respondErr Submission.WikiNotFound

                        Just wiki ->
                            if not wiki.active then
                                respondErr Submission.WikiInactive

                            else
                                case Submission.validateNewPageFields body.rawPageSlug body.rawMarkdown body.rawTags of
                                    Err ve ->
                                        respondErr (Submission.Validation ve)

                                    Ok payload ->
                                        if Dict.member payload.pageSlug wiki.pages then
                                            respondErr Submission.SlugAlreadyInUse

                                        else if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                                            if Submission.pendingNewPageSlugBlocksTrustedPublish accountId wikiSlug payload.pageSlug model.submissions then
                                                respondErr Submission.SlugAlreadyInUse

                                            else
                                                let
                                                    submissionsAfterDraftCleanup : Dict String Submission.Submission
                                                    submissionsAfterDraftCleanup =
                                                        Submission.removeAuthorDraftNewPageSubmissionsForSlug accountId wikiSlug payload.pageSlug model.submissions

                                                    nextWiki : Wiki
                                                    nextWiki =
                                                        Wiki.publishNewPageOnWiki payload wiki

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model
                                                            | wikis = Dict.insert wikiSlug nextWiki model.wikis
                                                            , submissions = submissionsAfterDraftCleanup
                                                        }
                                                            |> withWikiSearchAndTodosCaches wikiSlug nextWiki now

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit now
                                                            wikiSlug
                                                            accountId
                                                            (WikiAuditLog.TrustedPublishedNewPage
                                                                { pageSlug = payload.pageSlug
                                                                , markdown = payload.markdown
                                                                }
                                                            )
                                                            nextModel0
                                                in
                                                ( nextModel
                                                , Command.batch
                                                    [ Effect.Lamdera.sendToFrontend clientId
                                                        (SubmitNewPageResponse wikiSlug (Ok Submission.NewPagePublishedImmediately))
                                                    , broadcastWikiFrontendDetails wikiSlug nextModel
                                                    , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                    ]
                                                )

                                        else if Submission.pendingNewPageSlugInUse wikiSlug payload.pageSlug model.submissions then
                                            respondErr Submission.SlugAlreadyInUse

                                        else
                                            let
                                                submissionId : Submission.Id
                                                submissionId =
                                                    Submission.idFromCounter model.nextSubmissionCounter

                                                sub : Submission.Submission
                                                sub =
                                                    { id = submissionId
                                                    , wikiSlug = wikiSlug
                                                    , authorId = accountId
                                                    , kind =
                                                        Submission.NewPage
                                                            { pageSlug = payload.pageSlug
                                                            , markdown = payload.markdown
                                                            , tags = payload.tags
                                                            }
                                                    , status = Submission.Pending
                                                    , reviewerNote = Nothing
                                                    }

                                                inserted : Dict String Submission.Submission
                                                inserted =
                                                    Dict.insert (Submission.idToString submissionId) sub model.submissions

                                                nextModel : Model
                                                nextModel =
                                                    withPendingMutation wikiSlug
                                                        { model
                                                            | submissions = inserted
                                                            , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                        }
                                            in
                                            ( nextModel
                                            , Command.batch
                                                [ Effect.Lamdera.sendToFrontend clientId
                                                    (SubmitNewPageResponse wikiSlug (Ok (Submission.NewPageSubmittedForReview submissionId)))
                                                , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                ]
                                            )

        SubmitPageEdit wikiSlug pageSlug rawMarkdown rawTags ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.SubmitPageEditError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmitPageEditResponse wikiSlug (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.EditNotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.EditWrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respondErr Submission.EditWikiNotFound

                        Just wiki ->
                            if not wiki.active then
                                respondErr Submission.EditWikiInactive

                            else
                                case Submission.validateEditMarkdown rawMarkdown rawTags pageSlug of
                                    Err ve ->
                                        respondErr (Submission.EditValidation ve)

                                    Ok validEdit ->
                                        if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                            respondErr Submission.EditTargetPageNotPublished

                                        else if Submission.pendingEditForAuthorOnPageInUse wikiSlug accountId pageSlug model.submissions then
                                            respondErr Submission.EditAlreadyPendingForAuthor

                                        else if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                                            let
                                                previousMarkdown : String
                                                previousMarkdown =
                                                    SubmissionReviewDetail.publishedMarkdownForSlug wiki pageSlug

                                                nextWiki : Wiki
                                                nextWiki =
                                                    Wiki.applyPublishedMarkdownEdit pageSlug validEdit.proposedMarkdown validEdit.tags wiki

                                                nextModel0 : Model
                                                nextModel0 =
                                                    { model
                                                        | wikis = Dict.insert wikiSlug nextWiki model.wikis
                                                    }
                                                        |> withWikiSearchAndTodosCaches wikiSlug nextWiki now

                                                nextModel : Model
                                                nextModel =
                                                    recordAudit now
                                                        wikiSlug
                                                        accountId
                                                        (WikiAuditLog.TrustedPublishedPageEdit
                                                            { pageSlug = pageSlug
                                                            , beforeMarkdown = previousMarkdown
                                                            , afterMarkdown = validEdit.proposedMarkdown
                                                            }
                                                        )
                                                        nextModel0
                                            in
                                            ( nextModel
                                            , Command.batch
                                                [ Effect.Lamdera.sendToFrontend clientId
                                                    (SubmitPageEditResponse wikiSlug (Ok Submission.EditPublishedImmediately))
                                                , broadcastWikiFrontendDetails wikiSlug nextModel
                                                , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                ]
                                            )

                                        else
                                            let
                                                baseMarkdown : String
                                                baseMarkdown =
                                                    SubmissionReviewDetail.publishedMarkdownForSlug wiki pageSlug

                                                baseRevision : Int
                                                baseRevision =
                                                    Submission.currentPublishedRevision wiki pageSlug
                                                        |> Maybe.withDefault 0

                                                submissionId : Submission.Id
                                                submissionId =
                                                    Submission.idFromCounter model.nextSubmissionCounter

                                                sub : Submission.Submission
                                                sub =
                                                    { id = submissionId
                                                    , wikiSlug = wikiSlug
                                                    , authorId = accountId
                                                    , kind =
                                                        Submission.EditPage
                                                            { pageSlug = pageSlug
                                                            , baseMarkdown = baseMarkdown
                                                            , baseRevision = baseRevision
                                                            , proposedMarkdown = validEdit.proposedMarkdown
                                                            , tags = validEdit.tags
                                                            }
                                                    , status = Submission.Pending
                                                    , reviewerNote = Nothing
                                                    }

                                                inserted : Dict String Submission.Submission
                                                inserted =
                                                    Dict.insert (Submission.idToString submissionId) sub model.submissions

                                                nextModel : Model
                                                nextModel =
                                                    withPendingMutation wikiSlug
                                                        { model
                                                            | submissions = inserted
                                                            , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                        }
                                            in
                                            ( nextModel
                                            , Command.batch
                                                [ Effect.Lamdera.sendToFrontend clientId
                                                    (SubmitPageEditResponse wikiSlug (Ok (Submission.EditSubmittedForReview submissionId)))
                                                , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                ]
                                            )

        RequestPublishedPageDeletion wikiSlug pageSlug rawReason ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.RequestPublishedPageDeletionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RequestPublishedPageDeletionResponse wikiSlug (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                        respondErr Submission.RequestPublishedPageDeletionForbiddenTrustedModerator

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionWikiNotFound)

                            Just wiki ->
                                if not wiki.active then
                                    respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionWikiInactive)

                                else
                                    case Submission.validateDeleteReasonRequired rawReason of
                                        Err ve ->
                                            respondErr (Submission.RequestPublishedPageDeletionPrecondition (Submission.PageDeletionValidation ve))

                                        Ok deletionReason ->
                                            if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                                respondErr (Submission.RequestPublishedPageDeletionPrecondition Submission.PageDeletionTargetNotPublished)

                                            else
                                                let
                                                    submissionId : Submission.Id
                                                    submissionId =
                                                        Submission.idFromCounter model.nextSubmissionCounter

                                                    sub : Submission.Submission
                                                    sub =
                                                        { id = submissionId
                                                        , wikiSlug = wikiSlug
                                                        , authorId = accountId
                                                        , kind =
                                                            Submission.DeletePage
                                                                { pageSlug = pageSlug
                                                                , reason = Just deletionReason
                                                                }
                                                        , status = Submission.Pending
                                                        , reviewerNote = Nothing
                                                        }

                                                    inserted : Dict String Submission.Submission
                                                    inserted =
                                                        Dict.insert (Submission.idToString submissionId) sub model.submissions

                                                    nextModel : Model
                                                    nextModel =
                                                        withPendingMutation wikiSlug
                                                            { model
                                                                | submissions = inserted
                                                                , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                            }
                                                in
                                                ( nextModel
                                                , Command.batch
                                                    [ Effect.Lamdera.sendToFrontend clientId
                                                        (RequestPublishedPageDeletionResponse wikiSlug (Ok submissionId))
                                                    , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                    ]
                                                )

        DeletePublishedPageImmediately wikiSlug pageSlug rawReason ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.DeletePublishedPageImmediatelyError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DeletePublishedPageImmediatelyResponse wikiSlug (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respondErr Submission.DeletePublishedPageImmediatelyForbiddenUntrustedContributor

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionWikiNotFound)

                            Just wiki ->
                                if not wiki.active then
                                    respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionWikiInactive)

                                else
                                    case Submission.validateDeleteReasonRequired rawReason of
                                        Err ve ->
                                            respondErr (Submission.DeletePublishedPageImmediatelyPrecondition (Submission.PageDeletionValidation ve))

                                        Ok deletionReason ->
                                            if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                                respondErr (Submission.DeletePublishedPageImmediatelyPrecondition Submission.PageDeletionTargetNotPublished)

                                            else
                                                let
                                                    nextWiki : Wiki
                                                    nextWiki =
                                                        Wiki.removePublishedPage pageSlug wiki

                                                    nextModel0 : Model
                                                    nextModel0 =
                                                        { model
                                                            | wikis = Dict.insert wikiSlug nextWiki model.wikis
                                                        }
                                                            |> withWikiSearchAndTodosCaches wikiSlug nextWiki now

                                                    nextModel : Model
                                                    nextModel =
                                                        recordAudit now
                                                            wikiSlug
                                                            accountId
                                                            (WikiAuditLog.TrustedPublishedPageDelete
                                                                { pageSlug = pageSlug
                                                                , reason = deletionReason
                                                                }
                                                            )
                                                            nextModel0
                                                in
                                                ( nextModel
                                                , Command.batch
                                                    [ Effect.Lamdera.sendToFrontend clientId
                                                        (DeletePublishedPageImmediatelyResponse wikiSlug (Ok ()))
                                                    , broadcastWikiFrontendDetails wikiSlug nextModel
                                                    , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                    ]
                                                )

        SaveNewPageDraft wikiSlug payload ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.SaveNewPageDraftError Submission.Id -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SaveNewPageDraftResponse wikiSlug res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.SaveNewPageDraftNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.SaveNewPageDraftWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.SaveNewPageDraftWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.SaveNewPageDraftWikiInactive)

                            else
                                case Submission.validateNewPageDraftFields payload.rawPageSlug payload.rawMarkdown payload.rawTags of
                                    Err ve ->
                                        respond (Err (Submission.SaveNewPageDraftValidation ve))

                                    Ok draftPayload ->
                                        case payload.maybeSubmissionId of
                                            Nothing ->
                                                if Submission.pendingNewPageSlugInUse wikiSlug draftPayload.pageSlug model.submissions then
                                                    respond (Err Submission.SaveNewPageDraftSlugReserved)

                                                else
                                                    let
                                                        submissionId : Submission.Id
                                                        submissionId =
                                                            Submission.idFromCounter model.nextSubmissionCounter

                                                        sub : Submission.Submission
                                                        sub =
                                                            { id = submissionId
                                                            , wikiSlug = wikiSlug
                                                            , authorId = accountId
                                                            , kind =
                                                                Submission.NewPage
                                                                    { pageSlug = draftPayload.pageSlug
                                                                    , markdown = draftPayload.markdown
                                                                    , tags = draftPayload.tags
                                                                    }
                                                            , status = Submission.Draft
                                                            , reviewerNote = Nothing
                                                            }

                                                        nextModel : Model
                                                        nextModel =
                                                            { model
                                                                | submissions =
                                                                    Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                                , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                            }
                                                    in
                                                    ( nextModel
                                                    , Effect.Lamdera.sendToFrontend clientId
                                                        (SaveNewPageDraftResponse wikiSlug (Ok submissionId))
                                                    )

                                            Just sid ->
                                                case Dict.get sid model.submissions of
                                                    Nothing ->
                                                        respond (Err Submission.SaveNewPageDraftNotFound)

                                                    Just sub ->
                                                        if sub.wikiSlug /= wikiSlug then
                                                            respond (Err Submission.SaveNewPageDraftNotFound)

                                                        else if sub.authorId /= accountId then
                                                            respond (Err Submission.SaveNewPageDraftForbidden)

                                                        else if sub.status /= Submission.Draft then
                                                            respond (Err Submission.SaveNewPageDraftForbidden)

                                                        else
                                                            case sub.kind of
                                                                Submission.NewPage _ ->
                                                                    if Submission.pendingNewPageSlugInUseExcept (Just sub.id) wikiSlug draftPayload.pageSlug model.submissions then
                                                                        respond (Err Submission.SaveNewPageDraftSlugReserved)

                                                                    else
                                                                        let
                                                                            nextSub : Submission.Submission
                                                                            nextSub =
                                                                                { sub
                                                                                    | kind =
                                                                                        Submission.NewPage
                                                                                            { pageSlug = draftPayload.pageSlug
                                                                                            , markdown = draftPayload.markdown
                                                                                            , tags = draftPayload.tags
                                                                                            }
                                                                                }
                                                                        in
                                                                        ( { model
                                                                            | submissions =
                                                                                Dict.insert sid nextSub model.submissions
                                                                          }
                                                                        , Effect.Lamdera.sendToFrontend clientId
                                                                            (SaveNewPageDraftResponse wikiSlug (Ok sub.id))
                                                                        )

                                                                Submission.EditPage _ ->
                                                                    respond (Err Submission.SaveNewPageDraftForbidden)

                                                                Submission.DeletePage _ ->
                                                                    respond (Err Submission.SaveNewPageDraftForbidden)

        SavePageEditDraft wikiSlug payload ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.SavePageEditDraftError Submission.Id -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SavePageEditDraftResponse wikiSlug res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.SavePageEditDraftNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.SavePageEditDraftWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.SavePageEditDraftWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.SavePageEditDraftWikiInactive)

                            else
                                case Submission.validateEditMarkdownDraft payload.rawMarkdown payload.rawTags payload.pageSlug of
                                    Err ve ->
                                        respond (Err (Submission.SavePageEditDraftValidation ve))

                                    Ok draftEdit ->
                                        let
                                            pageSlug : Page.Slug
                                            pageSlug =
                                                payload.pageSlug
                                        in
                                        if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                            respond (Err Submission.SavePageEditDraftTargetNotPublished)

                                        else
                                            let
                                                baseMarkdown : String
                                                baseMarkdown =
                                                    SubmissionReviewDetail.publishedMarkdownForSlug wiki pageSlug

                                                baseRevision : Int
                                                baseRevision =
                                                    Submission.currentPublishedRevision wiki pageSlug
                                                        |> Maybe.withDefault 0
                                            in
                                            case payload.maybeSubmissionId of
                                                Nothing ->
                                                    if Submission.pendingEditForAuthorOnPageInUse wikiSlug accountId pageSlug model.submissions then
                                                        respond (Err Submission.SavePageEditDraftAlreadyPendingEdit)

                                                    else
                                                        let
                                                            submissionId : Submission.Id
                                                            submissionId =
                                                                Submission.idFromCounter model.nextSubmissionCounter

                                                            sub : Submission.Submission
                                                            sub =
                                                                { id = submissionId
                                                                , wikiSlug = wikiSlug
                                                                , authorId = accountId
                                                                , kind =
                                                                    Submission.EditPage
                                                                        { pageSlug = pageSlug
                                                                        , baseMarkdown = baseMarkdown
                                                                        , baseRevision = baseRevision
                                                                        , proposedMarkdown = draftEdit.proposedMarkdown
                                                                        , tags = draftEdit.tags
                                                                        }
                                                                , status = Submission.Draft
                                                                , reviewerNote = Nothing
                                                                }

                                                            nextModel : Model
                                                            nextModel =
                                                                { model
                                                                    | submissions =
                                                                        Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                                    , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                                }
                                                        in
                                                        ( nextModel
                                                        , Effect.Lamdera.sendToFrontend clientId
                                                            (SavePageEditDraftResponse wikiSlug (Ok submissionId))
                                                        )

                                                Just sid ->
                                                    case Dict.get sid model.submissions of
                                                        Nothing ->
                                                            respond (Err Submission.SavePageEditDraftNotFound)

                                                        Just sub ->
                                                            if sub.wikiSlug /= wikiSlug then
                                                                respond (Err Submission.SavePageEditDraftNotFound)

                                                            else if sub.authorId /= accountId then
                                                                respond (Err Submission.SavePageEditDraftForbidden)

                                                            else if sub.status /= Submission.Draft then
                                                                respond (Err Submission.SavePageEditDraftForbidden)

                                                            else
                                                                case sub.kind of
                                                                    Submission.EditPage body ->
                                                                        if body.pageSlug /= pageSlug then
                                                                            respond (Err Submission.SavePageEditDraftForbidden)

                                                                        else
                                                                            let
                                                                                nextSub : Submission.Submission
                                                                                nextSub =
                                                                                    { sub
                                                                                        | kind =
                                                                                            Submission.EditPage
                                                                                                { pageSlug = pageSlug
                                                                                                , baseMarkdown = baseMarkdown
                                                                                                , baseRevision = baseRevision
                                                                                                , proposedMarkdown = draftEdit.proposedMarkdown
                                                                                                , tags = draftEdit.tags
                                                                                                }
                                                                                    }
                                                                            in
                                                                            ( { model
                                                                                | submissions =
                                                                                    Dict.insert sid nextSub model.submissions
                                                                              }
                                                                            , Effect.Lamdera.sendToFrontend clientId
                                                                                (SavePageEditDraftResponse wikiSlug (Ok sub.id))
                                                                            )

                                                                    Submission.NewPage _ ->
                                                                        respond (Err Submission.SavePageEditDraftForbidden)

                                                                    Submission.DeletePage _ ->
                                                                        respond (Err Submission.SavePageEditDraftForbidden)

        SavePageDeleteDraft wikiSlug payload ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.SavePageDeleteDraftError Submission.Id -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SavePageDeleteDraftResponse wikiSlug res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.SavePageDeleteDraftNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.SavePageDeleteDraftWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    if WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors then
                        respond (Err Submission.SavePageDeleteDraftForbiddenTrustedModerator)

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respond (Err Submission.SavePageDeleteDraftWikiNotFound)

                            Just wiki ->
                                if not wiki.active then
                                    respond (Err Submission.SavePageDeleteDraftWikiInactive)

                                else
                                    case Submission.validateDeleteReasonRequired payload.rawReason of
                                        Err ve ->
                                            respond (Err (Submission.SavePageDeleteDraftReasonInvalid ve))

                                        Ok deletionReason ->
                                            let
                                                pageSlug : Page.Slug
                                                pageSlug =
                                                    payload.pageSlug
                                            in
                                            if not (Submission.wikiHasPublishedPage pageSlug wiki) then
                                                respond (Err Submission.SavePageDeleteDraftTargetNotPublished)

                                            else
                                                case payload.maybeSubmissionId of
                                                    Nothing ->
                                                        let
                                                            submissionId : Submission.Id
                                                            submissionId =
                                                                Submission.idFromCounter model.nextSubmissionCounter

                                                            sub : Submission.Submission
                                                            sub =
                                                                { id = submissionId
                                                                , wikiSlug = wikiSlug
                                                                , authorId = accountId
                                                                , kind =
                                                                    Submission.DeletePage
                                                                        { pageSlug = pageSlug
                                                                        , reason = Just deletionReason
                                                                        }
                                                                , status = Submission.Draft
                                                                , reviewerNote = Nothing
                                                                }

                                                            nextModel : Model
                                                            nextModel =
                                                                { model
                                                                    | submissions =
                                                                        Dict.insert (Submission.idToString submissionId) sub model.submissions
                                                                    , nextSubmissionCounter = model.nextSubmissionCounter + 1
                                                                }
                                                        in
                                                        ( nextModel
                                                        , Effect.Lamdera.sendToFrontend clientId
                                                            (SavePageDeleteDraftResponse wikiSlug (Ok submissionId))
                                                        )

                                                    Just sid ->
                                                        case Dict.get sid model.submissions of
                                                            Nothing ->
                                                                respond (Err Submission.SavePageDeleteDraftNotFound)

                                                            Just sub ->
                                                                if sub.wikiSlug /= wikiSlug then
                                                                    respond (Err Submission.SavePageDeleteDraftNotFound)

                                                                else if sub.authorId /= accountId then
                                                                    respond (Err Submission.SavePageDeleteDraftForbidden)

                                                                else if sub.status /= Submission.Draft then
                                                                    respond (Err Submission.SavePageDeleteDraftForbidden)

                                                                else
                                                                    case sub.kind of
                                                                        Submission.DeletePage body ->
                                                                            if body.pageSlug /= pageSlug then
                                                                                respond (Err Submission.SavePageDeleteDraftForbidden)

                                                                            else
                                                                                let
                                                                                    nextSub : Submission.Submission
                                                                                    nextSub =
                                                                                        { sub
                                                                                            | kind =
                                                                                                Submission.DeletePage
                                                                                                    { pageSlug = pageSlug
                                                                                                    , reason = Just deletionReason
                                                                                                    }
                                                                                        }
                                                                                in
                                                                                ( { model
                                                                                    | submissions =
                                                                                        Dict.insert sid nextSub model.submissions
                                                                                  }
                                                                                , Effect.Lamdera.sendToFrontend clientId
                                                                                    (SavePageDeleteDraftResponse wikiSlug (Ok sub.id))
                                                                                )

                                                                        Submission.NewPage _ ->
                                                                            respond (Err Submission.SavePageDeleteDraftForbidden)

                                                                        Submission.EditPage _ ->
                                                                            respond (Err Submission.SavePageDeleteDraftForbidden)

        SubmitDraftForReview wikiSlug submissionIdStr ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.SubmitDraftForReviewError () -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (SubmitDraftForReviewResponse wikiSlug submissionIdStr res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.SubmitDraftForReviewNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.SubmitDraftForReviewWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.SubmitDraftForReviewWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.SubmitDraftForReviewWikiInactive)

                            else
                                case Dict.get submissionIdStr model.submissions of
                                    Nothing ->
                                        respond (Err Submission.SubmitDraftForReviewNotFound)

                                    Just sub ->
                                        if sub.wikiSlug /= wikiSlug then
                                            respond (Err Submission.SubmitDraftForReviewNotFound)

                                        else if sub.authorId /= accountId then
                                            respond (Err Submission.SubmitDraftForReviewForbidden)

                                        else
                                            case ( sub.kind, WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors ) of
                                                ( Submission.DeletePage _, True ) ->
                                                    respond (Err Submission.SubmitDraftForReviewDeleteForbiddenTrustedModerator)

                                                _ ->
                                                    case Submission.promoteDraftToPending wiki model.submissions sub of
                                                        Err e ->
                                                            respond (Err e)

                                                        Ok nextSub ->
                                                            let
                                                                inserted : Dict String Submission.Submission
                                                                inserted =
                                                                    Dict.insert submissionIdStr nextSub model.submissions

                                                                nextModel : Model
                                                                nextModel =
                                                                    withSubmissionMutation sub (Just nextSub) wikiSlug { model | submissions = inserted }
                                                            in
                                                            ( nextModel
                                                            , Command.batch
                                                                [ Effect.Lamdera.sendToFrontend clientId
                                                                    (SubmitDraftForReviewResponse wikiSlug submissionIdStr (Ok ()))
                                                                , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                                ]
                                                            )

        WithdrawSubmission wikiSlug submissionIdStr ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.WithdrawSubmissionError () -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (WithdrawSubmissionResponse wikiSlug submissionIdStr res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.WithdrawSubmissionNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.WithdrawSubmissionWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.WithdrawSubmissionWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.WithdrawSubmissionWikiInactive)

                            else
                                case Dict.get submissionIdStr model.submissions of
                                    Nothing ->
                                        respond (Err Submission.WithdrawSubmissionNotFound)

                                    Just sub ->
                                        if sub.wikiSlug /= wikiSlug then
                                            respond (Err Submission.WithdrawSubmissionNotFound)

                                        else if sub.authorId /= accountId then
                                            respond (Err Submission.WithdrawSubmissionForbidden)

                                        else
                                            case Submission.withdrawSubmissionToDraft sub of
                                                Err e ->
                                                    respond (Err e)

                                                Ok nextSub ->
                                                    let
                                                        inserted : Dict String Submission.Submission
                                                        inserted =
                                                            Dict.insert submissionIdStr nextSub model.submissions

                                                        nextModel : Model
                                                        nextModel =
                                                            withSubmissionMutation sub (Just nextSub) wikiSlug { model | submissions = inserted }
                                                    in
                                                    ( nextModel
                                                    , Command.batch
                                                        [ Effect.Lamdera.sendToFrontend clientId
                                                            (WithdrawSubmissionResponse wikiSlug submissionIdStr (Ok ()))
                                                        , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                        ]
                                                    )

        DeleteMySubmission wikiSlug submissionIdStr ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond : Result Submission.DeleteMySubmissionError () -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DeleteMySubmissionResponse wikiSlug submissionIdStr res)
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respond (Err Submission.DeleteMySubmissionNotLoggedIn)

                WikiUser.SessionWrongWiki ->
                    respond (Err Submission.DeleteMySubmissionWrongWikiSession)

                WikiUser.SessionHasAccount accountId ->
                    case Dict.get wikiSlug model.wikis of
                        Nothing ->
                            respond (Err Submission.DeleteMySubmissionWikiNotFound)

                        Just wiki ->
                            if not wiki.active then
                                respond (Err Submission.DeleteMySubmissionWikiInactive)

                            else
                                case Dict.get submissionIdStr model.submissions of
                                    Nothing ->
                                        respond (Err Submission.DeleteMySubmissionNotFound)

                                    Just sub ->
                                        if sub.wikiSlug /= wikiSlug then
                                            respond (Err Submission.DeleteMySubmissionNotFound)

                                        else if sub.authorId /= accountId then
                                            respond (Err Submission.DeleteMySubmissionForbidden)

                                        else
                                            case Submission.mayContributorDeleteSubmission sub of
                                                Err e ->
                                                    respond (Err e)

                                                Ok () ->
                                                    let
                                                        nextSubmissions : Dict String Submission.Submission
                                                        nextSubmissions =
                                                            Dict.remove submissionIdStr model.submissions

                                                        nextModel : Model
                                                        nextModel =
                                                            withSubmissionMutation sub Nothing wikiSlug { model | submissions = nextSubmissions }
                                                    in
                                                    ( nextModel
                                                    , Command.batch
                                                        [ Effect.Lamdera.sendToFrontend clientId
                                                            (DeleteMySubmissionResponse wikiSlug submissionIdStr (Ok ()))
                                                        , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                        ]
                                                    )

        ApproveSubmission wikiSlug submissionId ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : Submission.ApproveSubmissionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ApproveSubmissionResponse wikiSlug submissionId (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.ApproveNotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.ApproveWrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respondErr Submission.ApproveForbidden

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.ApproveWikiNotFound

                            Just wiki ->
                                if not wiki.active then
                                    respondErr Submission.ApproveWikiInactive

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respondErr Submission.ApproveSubmissionNotFound

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respondErr Submission.ApproveSubmissionNotFound

                                            else
                                                case Submission.applyApprovedSubmission wiki sub of
                                                    Err e ->
                                                        respondErr e

                                                    Ok approved ->
                                                        let
                                                            pageSlug : String
                                                            pageSlug =
                                                                Submission.pageSlugFromKind sub.kind
                                                                    |> Maybe.withDefault ""

                                                            submissionsAfterApproval : Dict String Submission.Submission
                                                            submissionsAfterApproval =
                                                                case sub.kind of
                                                                    Submission.EditPage editBody ->
                                                                        let
                                                                            maybeCurrentRevision : Maybe Int
                                                                            maybeCurrentRevision =
                                                                                Submission.currentPublishedRevision approved.wiki editBody.pageSlug
                                                                        in
                                                                        case maybeCurrentRevision of
                                                                            Nothing ->
                                                                                Dict.insert submissionId approved.submission model.submissions

                                                                            Just currentRevision ->
                                                                                let
                                                                                    staleNote : String
                                                                                    staleNote =
                                                                                        "Page changed after this edit was submitted. Withdraw the submission, update your draft against the latest page, and submit for review again."
                                                                                in
                                                                                model.submissions
                                                                                    |> Dict.insert submissionId approved.submission
                                                                                    |> Dict.map
                                                                                        (\subId candidate ->
                                                                                            if subId == submissionId || candidate.wikiSlug /= wikiSlug then
                                                                                                candidate

                                                                                            else if Submission.isStalePendingEditSubmission { pageSlug = editBody.pageSlug, currentRevision = currentRevision } candidate then
                                                                                                Submission.markStalePendingEditNeedsRevision staleNote candidate

                                                                                            else
                                                                                                candidate
                                                                                        )

                                                                    Submission.NewPage _ ->
                                                                        Dict.insert submissionId approved.submission model.submissions

                                                                    Submission.DeletePage _ ->
                                                                        Dict.insert submissionId approved.submission model.submissions

                                                            nextModel0 : Model
                                                            nextModel0 =
                                                                { model
                                                                    | wikis = Dict.insert wikiSlug approved.wiki model.wikis
                                                                    , submissions = submissionsAfterApproval
                                                                }
                                                                    |> withWikiSearchAndTodosCaches wikiSlug approved.wiki now

                                                            approvedAuditKind : WikiAuditLog.AuditEventKind
                                                            approvedAuditKind =
                                                                case sub.kind of
                                                                    Submission.NewPage _ ->
                                                                        WikiAuditLog.ApprovedPublishedNewPage
                                                                            { submissionId = submissionId
                                                                            , pageSlug = pageSlug
                                                                            }

                                                                    Submission.EditPage _ ->
                                                                        WikiAuditLog.ApprovedPublishedPageEdit
                                                                            { submissionId = submissionId
                                                                            , pageSlug = pageSlug
                                                                            }

                                                                    Submission.DeletePage _ ->
                                                                        WikiAuditLog.ApprovedPublishedPageDelete
                                                                            { submissionId = submissionId
                                                                            , pageSlug = pageSlug
                                                                            }

                                                            nextModel : Model
                                                            nextModel =
                                                                withPendingMutation wikiSlug
                                                                    (recordAudit now
                                                                        wikiSlug
                                                                        accountId
                                                                        approvedAuditKind
                                                                        nextModel0
                                                                    )
                                                        in
                                                        ( nextModel
                                                        , Command.batch
                                                            [ Effect.Lamdera.sendToFrontend clientId
                                                                (ApproveSubmissionResponse wikiSlug submissionId (Ok ()))
                                                            , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                            , broadcastWikiFrontendDetails wikiSlug nextModel
                                                            , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                            ]
                                                        )

        RejectSubmission wikiSlug rej ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                submissionId : String
                submissionId =
                    rej.submissionId

                respondErr : Submission.RejectSubmissionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RejectSubmissionResponse wikiSlug submissionId (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.RejectNotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.RejectWrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respondErr Submission.RejectForbidden

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.RejectWikiNotFound

                            Just w ->
                                if not w.active then
                                    respondErr Submission.RejectWikiInactive

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respondErr Submission.RejectSubmissionNotFound

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respondErr Submission.RejectSubmissionNotFound

                                            else
                                                case Submission.rejectPendingSubmission rej.reasonText sub of
                                                    Err e ->
                                                        respondErr e

                                                    Ok rejected ->
                                                        let
                                                            pageSlug : String
                                                            pageSlug =
                                                                Submission.pageSlugFromKind sub.kind
                                                                    |> Maybe.withDefault ""

                                                            inserted : Dict String Submission.Submission
                                                            inserted =
                                                                Dict.insert submissionId rejected model.submissions

                                                            nextModel0 : Model
                                                            nextModel0 =
                                                                withSubmissionMutation sub (Just rejected) wikiSlug { model | submissions = inserted }

                                                            nextModel : Model
                                                            nextModel =
                                                                recordAudit now
                                                                    wikiSlug
                                                                    accountId
                                                                    (WikiAuditLog.RejectedSubmission
                                                                        { submissionId = submissionId
                                                                        , pageSlug = pageSlug
                                                                        }
                                                                    )
                                                                    nextModel0
                                                        in
                                                        ( nextModel
                                                        , Command.batch
                                                            [ Effect.Lamdera.sendToFrontend clientId
                                                                (RejectSubmissionResponse wikiSlug submissionId (Ok ()))
                                                            , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                            , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                            ]
                                                        )

        RequestSubmissionChanges wikiSlug req ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                submissionId : String
                submissionId =
                    req.submissionId

                respondErr : Submission.RequestChangesSubmissionError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr err =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (RequestSubmissionChangesResponse wikiSlug submissionId (Err err))
                    )
            in
            case WikiUser.sessionContributorOnWiki sessionKey wikiSlug model.contributorSessions of
                WikiUser.SessionNotLoggedIn ->
                    respondErr Submission.RequestChangesNotLoggedIn

                WikiUser.SessionWrongWiki ->
                    respondErr Submission.RequestChangesWrongWikiSession

                WikiUser.SessionHasAccount accountId ->
                    if not (WikiContributors.isTrustedForWiki wikiSlug accountId model.contributors) then
                        respondErr Submission.RequestChangesForbidden

                    else
                        case Dict.get wikiSlug model.wikis of
                            Nothing ->
                                respondErr Submission.RequestChangesWikiNotFound

                            Just w ->
                                if not w.active then
                                    respondErr Submission.RequestChangesWikiInactive

                                else
                                    case Dict.get submissionId model.submissions of
                                        Nothing ->
                                            respondErr Submission.RequestChangesSubmissionNotFound

                                        Just sub ->
                                            if sub.wikiSlug /= wikiSlug then
                                                respondErr Submission.RequestChangesSubmissionNotFound

                                            else
                                                case Submission.requestPendingSubmissionChanges req.guidanceText sub of
                                                    Err e ->
                                                        respondErr e

                                                    Ok needsRevision ->
                                                        let
                                                            pageSlug : String
                                                            pageSlug =
                                                                Submission.pageSlugFromKind sub.kind
                                                                    |> Maybe.withDefault ""

                                                            inserted : Dict String Submission.Submission
                                                            inserted =
                                                                Dict.insert submissionId needsRevision model.submissions

                                                            nextModel0 : Model
                                                            nextModel0 =
                                                                withSubmissionMutation sub (Just needsRevision) wikiSlug { model | submissions = inserted }

                                                            nextModel : Model
                                                            nextModel =
                                                                recordAudit now
                                                                    wikiSlug
                                                                    accountId
                                                                    (WikiAuditLog.RequestedSubmissionChanges
                                                                        { submissionId = submissionId
                                                                        , pageSlug = pageSlug
                                                                        }
                                                                    )
                                                                    nextModel0
                                                        in
                                                        ( nextModel
                                                        , Command.batch
                                                            [ Effect.Lamdera.sendToFrontend clientId
                                                                (RequestSubmissionChangesResponse wikiSlug submissionId (Ok ()))
                                                            , sendPendingReviewCountToTrustedSubscribers wikiSlug nextModel
                                                            , broadcastWikiCacheInvalidated wikiSlug nextModel
                                                            ]
                                                        )

        HostAdminLogin password ->
            if password == Env.hostAdminPassword then
                let
                    sessionKey : String
                    sessionKey =
                        Effect.Lamdera.sessionIdToString sessionId
                in
                ( { model | hostSessions = Set.insert sessionKey model.hostSessions }
                , Effect.Lamdera.sendToFrontend clientId (HostAdminLoginResponse (Ok ()))
                )

            else
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminLoginResponse (Err HostAdmin.WrongPassword))
                )

        RequestHostWikiList ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if Set.member sessionKey model.hostSessions then
                let
                    summaries : List Wiki.CatalogEntry
                    summaries =
                        model.wikis
                            |> Dict.values
                            |> List.map Wiki.catalogEntry
                            |> List.sortBy .slug
                in
                ( model
                , Effect.Lamdera.sendToFrontend clientId (HostAdminWikiListResponse (Ok summaries))
                )

            else
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminWikiListResponse (Err HostAdmin.NotHostAuthenticated))
                )

        RequestHostAuditLog filter ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond :
                    Result HostAdmin.ProtectedError (List WikiAuditLog.ScopedAuditEventSummary)
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (HostAuditLogResponse filter res)
                    )
            in
            if Set.member sessionKey model.hostSessions then
                model.wikiAuditEvents
                    |> WikiAuditLog.allScopedEventsFromDict
                    |> WikiAuditLog.filterScopedEvents filter
                    |> List.map WikiAuditLog.scopedEventSummaryFromScoped
                    |> Ok
                    |> respond

            else
                respond (Err HostAdmin.NotHostAuthenticated)

        RequestHostAuditEventDiff filter rowIndex ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respond :
                    Result HostAdmin.ProtectedError (Result WikiAuditLog.EventDiffError WikiAuditLog.TrustedPublishAuditDiff)
                    -> ( Model, Command BackendOnly ToFrontend Msg )
                respond res =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (HostAuditEventDiffResponse filter rowIndex res)
                    )
            in
            if Set.member sessionKey model.hostSessions then
                let
                    scoped : List WikiAuditLog.ScopedAuditEvent
                    scoped =
                        model.wikiAuditEvents
                            |> WikiAuditLog.allScopedEventsFromDict
                            |> WikiAuditLog.filterScopedEvents filter
                in
                case List.drop rowIndex scoped of
                    [] ->
                        respond (Ok (Err WikiAuditLog.DiffRowNotFound))

                    ev :: _ ->
                        case WikiAuditLog.trustedPublishDiffFromKind ev.kind of
                            Nothing ->
                                respond (Ok (Err WikiAuditLog.DiffRowNotDiffable))

                            Just body ->
                                respond (Ok (Ok body))

            else
                respond (Err HostAdmin.NotHostAuthenticated)

        CreateHostedWiki create ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.CreateHostedWikiError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId (CreateHostedWikiResponse (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.CreateNotHostAuthenticated

            else
                case Submission.validatePageSlug create.rawSlug of
                    Err ve ->
                        respondErr (HostAdmin.CreateSlugInvalid ve)

                    Ok slug ->
                        case HostAdmin.validateHostedWikiName create.rawName of
                            Err ne ->
                                respondErr (HostAdmin.CreateWikiNameInvalid ne)

                            Ok name ->
                                case ContributorAccount.validateRegistrationFields create.initialAdminUsername create.initialAdminPassword of
                                    Err regErr ->
                                        respondErr (HostAdmin.CreateInitialAdminInvalid regErr)

                                    Ok _ ->
                                        if Dict.member slug model.wikis then
                                            respondErr HostAdmin.CreateWikiSlugTaken

                                        else
                                            let
                                                wiki : Wiki
                                                wiki =
                                                    { slug = slug
                                                    , name = name
                                                    , summary = ""
                                                    , active = True
                                                    , contentVersion = 1
                                                    , pages = Dict.empty
                                                    }

                                                modelWithWiki : Model
                                                modelWithWiki =
                                                    { model | wikis = Dict.insert slug wiki model.wikis }
                                                        |> withWikiSearchAndTodosCaches slug wiki now
                                            in
                                            case
                                                WikiContributors.seedAdminContributorAtWiki
                                                    slug
                                                    create.initialAdminUsername
                                                    create.initialAdminPassword
                                                    modelWithWiki.wikis
                                                    modelWithWiki.contributors
                                            of
                                                Err regErr2 ->
                                                    ( model
                                                    , Effect.Lamdera.sendToFrontend clientId
                                                        (CreateHostedWikiResponse (Err (HostAdmin.CreateInitialAdminInvalid regErr2)))
                                                    )

                                                Ok nextContributors ->
                                                    let
                                                        nextWiki : Wiki
                                                        nextWiki =
                                                            Dict.get slug modelWithWiki.wikis
                                                                |> Maybe.withDefault wiki

                                                        nextModel : Model
                                                        nextModel =
                                                            { modelWithWiki | contributors = nextContributors }
                                                    in
                                                    ( nextModel
                                                    , Command.batch
                                                        [ Effect.Lamdera.sendToFrontend clientId
                                                            (CreateHostedWikiResponse (Ok (Wiki.catalogEntry nextWiki)))
                                                        , broadcastWikiCatalog nextModel
                                                        ]
                                                    )

        RequestHostWikiDetail wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostWikiDetailResponse wikiSlug (Err HostAdmin.HostWikiDetailNotHostAuthenticated))
                )

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostWikiDetailResponse wikiSlug (Err HostAdmin.HostWikiDetailWikiNotFound))
                        )

                    Just wiki ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostWikiDetailResponse wikiSlug (Ok (Wiki.catalogEntry wiki)))
                        )

        UpdateHostedWikiMetadata wikiSlug meta ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.UpdateHostedWikiMetadataError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (UpdateHostedWikiMetadataResponse wikiSlug (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.UpdateMetadataNotHostAuthenticated

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respondErr HostAdmin.UpdateMetadataWikiNotFound

                    Just wiki ->
                        case HostAdmin.validateHostedWikiName meta.rawName of
                            Err ne ->
                                respondErr (HostAdmin.UpdateMetadataWikiNameInvalid ne)

                            Ok name ->
                                case HostAdmin.validateHostedWikiSummary meta.rawSummary of
                                    Err se ->
                                        respondErr (HostAdmin.UpdateMetadataWikiSummaryInvalid se)

                                    Ok summaryText ->
                                        case HostAdmin.validateHostedWikiMetadataSlug wiki.slug meta.rawSlugDraft of
                                            Err slugErr ->
                                                respondErr slugErr

                                            Ok newSlug ->
                                                let
                                                    nextWikiBase : Wiki
                                                    nextWikiBase =
                                                        { wiki
                                                            | name = name
                                                            , summary = summaryText
                                                        }

                                                    nextWiki : Wiki
                                                    nextWiki =
                                                        { nextWikiBase | slug = newSlug }
                                                in
                                                if newSlug == wikiSlug then
                                                    let
                                                        nextModel : Model
                                                        nextModel =
                                                            { model | wikis = Dict.insert wikiSlug nextWiki model.wikis }
                                                                |> withWikiSearchAndTodosCaches wikiSlug nextWiki now
                                                    in
                                                    ( nextModel
                                                    , Command.batch
                                                        [ Effect.Lamdera.sendToFrontend clientId
                                                            (UpdateHostedWikiMetadataResponse wikiSlug (Ok (Wiki.catalogEntry nextWiki)))
                                                        , broadcastWikiCatalog nextModel
                                                        ]
                                                    )

                                                else if Dict.member newSlug model.wikis then
                                                    respondErr HostAdmin.UpdateMetadataWikiSlugTaken

                                                else
                                                    let
                                                        nextModel : Model
                                                        nextModel =
                                                            applyHostedWikiSlugRename wikiSlug newSlug nextWiki model
                                                    in
                                                    ( nextModel
                                                    , Command.batch
                                                        [ Effect.Lamdera.sendToFrontend clientId
                                                            (UpdateHostedWikiMetadataResponse wikiSlug (Ok (Wiki.catalogEntry nextWiki)))
                                                        , broadcastWikiCatalog nextModel
                                                        , broadcastWikiSlugRenamed wikiSlug newSlug nextModel
                                                        , broadcastWikiFrontendDetails newSlug nextModel
                                                        , broadcastWikiCacheInvalidated newSlug nextModel
                                                        ]
                                                    )

        DeactivateHostedWiki wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.WikiLifecycleError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DeactivateHostedWikiResponse wikiSlug (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.WikiLifecycleNotHostAuthenticated

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respondErr HostAdmin.WikiLifecycleWikiNotFound

                    Just wiki ->
                        let
                            nextWiki : Wiki
                            nextWiki =
                                { wiki | active = False }

                            nextModel : Model
                            nextModel =
                                { model | wikis = Dict.insert wikiSlug nextWiki model.wikis }
                                    |> withWikiSearchAndTodosCaches wikiSlug nextWiki now
                        in
                        ( nextModel
                        , Command.batch
                            [ Effect.Lamdera.sendToFrontend clientId
                                (DeactivateHostedWikiResponse wikiSlug (Ok (Wiki.catalogEntry nextWiki)))
                            , broadcastWikiCatalog nextModel
                            , broadcastWikiFrontendDetails wikiSlug nextModel
                            , broadcastWikiCacheInvalidated wikiSlug nextModel
                            ]
                        )

        ReactivateHostedWiki wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.WikiLifecycleError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (ReactivateHostedWikiResponse wikiSlug (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.WikiLifecycleNotHostAuthenticated

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respondErr HostAdmin.WikiLifecycleWikiNotFound

                    Just wiki ->
                        let
                            nextWiki : Wiki
                            nextWiki =
                                { wiki | active = True }

                            nextModel : Model
                            nextModel =
                                { model | wikis = Dict.insert wikiSlug nextWiki model.wikis }
                                    |> withWikiSearchAndTodosCaches wikiSlug nextWiki now
                        in
                        ( nextModel
                        , Command.batch
                            [ Effect.Lamdera.sendToFrontend clientId
                                (ReactivateHostedWikiResponse wikiSlug (Ok (Wiki.catalogEntry nextWiki)))
                            , broadcastWikiCatalog nextModel
                            , broadcastWikiFrontendDetails wikiSlug nextModel
                            , broadcastWikiCacheInvalidated wikiSlug nextModel
                            ]
                        )

        DeleteHostedWiki wikiSlug confirmationPhrase ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId

                respondErr : HostAdmin.DeleteHostedWikiError -> ( Model, Command BackendOnly ToFrontend Msg )
                respondErr e =
                    ( model
                    , Effect.Lamdera.sendToFrontend clientId
                        (DeleteHostedWikiResponse wikiSlug (Err e))
                    )
            in
            if not (Set.member sessionKey model.hostSessions) then
                respondErr HostAdmin.DeleteHostedWikiNotHostAuthenticated

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        respondErr HostAdmin.DeleteHostedWikiWikiNotFound

                    Just _ ->
                        if not (HostAdmin.deleteHostedWikiConfirmationMatches wikiSlug confirmationPhrase) then
                            respondErr HostAdmin.DeleteHostedWikiConfirmationMismatch

                        else
                            let
                                nextSubmissions : Dict String Submission.Submission
                                nextSubmissions =
                                    model.submissions
                                        |> Dict.filter (\_ sub -> sub.wikiSlug /= wikiSlug)

                                nextModel : Model
                                nextModel =
                                    { model
                                        | wikis = Dict.remove wikiSlug model.wikis
                                        , contributors = Dict.remove wikiSlug model.contributors
                                        , contributorSessions = WikiUser.dropBindingsForWiki wikiSlug model.contributorSessions
                                        , submissions = nextSubmissions
                                        , wikiAuditEvents = Dict.remove wikiSlug model.wikiAuditEvents
                                        , pendingReviewCounts = Dict.remove wikiSlug model.pendingReviewCounts
                                        , pendingReviewClients =
                                            PendingReviewCount.removeWikiSubscribers wikiSlug model.pendingReviewClients
                                        , wikiFrontendClients =
                                            WikiFrontendSubscription.removeWikiSubscribers wikiSlug model.wikiFrontendClients
                                        , wikiSearchIndexes = Dict.remove wikiSlug model.wikiSearchIndexes
                                        , wikiTodosCaches = Dict.remove wikiSlug model.wikiTodosCaches
                                        , pageViewCounts = Dict.remove wikiSlug model.pageViewCounts
                                        , wikiAuditVersions = Dict.remove wikiSlug model.wikiAuditVersions
                                        , wikiViewsVersions = Dict.remove wikiSlug model.wikiViewsVersions
                                        , wikiStatsCache = Dict.remove wikiSlug model.wikiStatsCache
                                    }
                            in
                            ( nextModel
                            , Command.batch
                                [ Effect.Lamdera.sendToFrontend clientId
                                    (DeleteHostedWikiResponse wikiSlug (Ok ()))
                                , broadcastWikiCatalog nextModel
                                ]
                            )

        RequestHostAdminDataExport ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminDataExportResponse (Err HostAdmin.DataExportNotHostAuthenticated))
                )

            else
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminDataExportResponse (Ok (BackendDataExport.encodeModelToJsonString model)))
                )

        ImportHostAdminDataSnapshot rawJson ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminDataImportResponse (Err HostAdmin.DataImportNotHostAuthenticated))
                )

            else
                case BackendDataExport.decodeImportString rawJson of
                    Err importErr ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminDataImportResponse
                                (Err
                                    (HostAdmin.DataImportInvalid (BackendDataExport.importErrorToString importErr))
                                )
                            )
                        )

                    Ok snap ->
                        let
                            nextModel : Model
                            nextModel =
                                BackendDataExport.applySnapshotToBackendModel snap model.hostSessions
                                    |> withRebuiltAllSearchAndTodosCaches now
                        in
                        ( nextModel
                        , Effect.Lamdera.sendToFrontend clientId (HostAdminDataImportResponse (Ok ()))
                        )

        RequestHostAdminWikiDataExport wikiSlug ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminWikiDataExportResponse wikiSlug (Err HostAdmin.WikiDataExportNotHostAuthenticated))
                )

            else
                case BackendDataExport.encodeWikiSnapshotToJsonString wikiSlug model of
                    Nothing ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminWikiDataExportResponse wikiSlug (Err HostAdmin.WikiDataExportWikiNotFound))
                        )

                    Just json ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminWikiDataExportResponse wikiSlug (Ok json))
                        )

        ImportHostAdminWikiDataSnapshot wikiSlug rawJson ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminWikiDataImportResponse wikiSlug (Err HostAdmin.WikiDataImportNotHostAuthenticated))
                )

            else
                case Dict.get wikiSlug model.wikis of
                    Nothing ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminWikiDataImportResponse wikiSlug (Err HostAdmin.WikiDataImportWikiNotFound))
                        )

                    Just _ ->
                        case BackendDataExport.decodeWikiImportForSlug wikiSlug rawJson of
                            Err importErr ->
                                ( model
                                , Effect.Lamdera.sendToFrontend clientId
                                    (HostAdminWikiDataImportResponse wikiSlug
                                        (Err
                                            (HostAdmin.WikiDataImportInvalid
                                                (BackendDataExport.importErrorToString importErr)
                                            )
                                        )
                                    )
                                )

                            Ok snap ->
                                case BackendDataExport.applyWikiSnapshotMerge wikiSlug snap model of
                                    Err detail ->
                                        ( model
                                        , Effect.Lamdera.sendToFrontend clientId
                                            (HostAdminWikiDataImportResponse wikiSlug
                                                (Err (HostAdmin.WikiDataImportInvalid detail))
                                            )
                                        )

                                    Ok nextModel ->
                                        let
                                            rebuiltModel : Model
                                            rebuiltModel =
                                                withRebuiltAllSearchAndTodosCaches now nextModel
                                        in
                                        ( rebuiltModel
                                        , Command.batch
                                            [ Effect.Lamdera.sendToFrontend clientId
                                                (HostAdminWikiDataImportResponse wikiSlug (Ok ()))
                                            , sendPendingReviewCountToTrustedSubscribers wikiSlug rebuiltModel
                                            ]
                                        )

        ImportHostAdminWikiDataSnapshotAuto rawJson ->
            let
                sessionKey : String
                sessionKey =
                    Effect.Lamdera.sessionIdToString sessionId
            in
            if not (Set.member sessionKey model.hostSessions) then
                ( model
                , Effect.Lamdera.sendToFrontend clientId
                    (HostAdminWikiDataImportAutoResponse (Err HostAdmin.WikiDataImportNotHostAuthenticated))
                )

            else
                case BackendDataExport.decodeWikiImportString rawJson of
                    Err importErr ->
                        ( model
                        , Effect.Lamdera.sendToFrontend clientId
                            (HostAdminWikiDataImportAutoResponse
                                (Err
                                    (HostAdmin.WikiDataImportInvalid
                                        (BackendDataExport.importErrorToString importErr)
                                    )
                                )
                            )
                        )

                    Ok ( wikiSlug, snap ) ->
                        case BackendDataExport.applyWikiSnapshotMerge wikiSlug snap model of
                            Err detail ->
                                ( model
                                , Effect.Lamdera.sendToFrontend clientId
                                    (HostAdminWikiDataImportAutoResponse
                                        (Err (HostAdmin.WikiDataImportInvalid detail))
                                    )
                                )

                            Ok nextModel ->
                                let
                                    rebuiltModel : Model
                                    rebuiltModel =
                                        withRebuiltAllSearchAndTodosCaches now nextModel
                                in
                                ( rebuiltModel
                                , Command.batch
                                    [ Effect.Lamdera.sendToFrontend clientId
                                        (HostAdminWikiDataImportAutoResponse (Ok wikiSlug))
                                    , sendPendingReviewCountToTrustedSubscribers wikiSlug rebuiltModel
                                    ]
                                )


subscriptions : Model -> Subscription BackendOnly Msg
subscriptions _ =
    Subscription.none


app_ :
    { init : ( Model, Command BackendOnly ToFrontend Msg )
    , update : Msg -> Model -> ( Model, Command BackendOnly ToFrontend Msg )
    , updateFromFrontend :
        SessionId
        -> ClientId
        -> ToBackend
        -> Model
        -> ( Model, Command BackendOnly ToFrontend Msg )
    , subscriptions : Model -> Subscription BackendOnly Msg
    }
app_ =
    { init = init
    , update = update
    , updateFromFrontend = updateFromFrontend
    , subscriptions = subscriptions
    }


app :
    { init : ( Model, Cmd Msg )
    , update : Msg -> Model -> ( Model, Cmd Msg )
    , updateFromFrontend : String -> String -> ToBackend -> Model -> ( Model, Cmd Msg )
    , subscriptions : Model -> Sub Msg
    }
app =
    Effect.Lamdera.backend Lamdera.broadcast Lamdera.sendToFrontend app_
