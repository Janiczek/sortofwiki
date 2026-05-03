module StoreTest exposing (suite)

import Dict exposing (Dict)
import Effect.Command as Command
import Effect.Lamdera
import Expect
import Frontend
import Fuzz
import Fuzzers
import Page
import RemoteData
import Store exposing (Store)
import Submission
import SubmissionReviewDetail
import Test exposing (Test)
import Types exposing (ToBackend(..))
import Wiki
import WikiAdminUsers
import WikiAuditLog


emptyAuditFilterCacheKey : String
emptyAuditFilterCacheKey =
    WikiAuditLog.auditLogFilterCacheKey WikiAuditLog.emptyAuditLogFilter


suite : Test
suite =
    Test.describe "Store"
        [ Test.describe "perform"
            [ Test.test "AskForWikiCatalog from empty sets Loading" <|
                \() ->
                    let
                        store : Store
                        store =
                            Store.empty
                    in
                    store
                        |> Store.perform Frontend.storeConfig Store.AskForWikiCatalog
                        |> Expect.equal
                            ( { store | wikiCatalog = RemoteData.Loading }
                            , Effect.Lamdera.sendToBackend RequestWikiCatalog
                            )
            , Test.test "AskForWikiCatalog skips when already Loading" <|
                \() ->
                    let
                        store : Store
                        store =
                            Store.empty
                    in
                    store
                        |> Store.perform Frontend.storeConfig Store.AskForWikiCatalog
                        -- set loading
                        |> Tuple.first
                        |> Store.perform Frontend.storeConfig Store.AskForWikiCatalog
                        -- ignoring because we're already loading
                        |> Expect.equal
                            ( { store | wikiCatalog = RemoteData.Loading }
                            , Command.none
                            )
            , Test.fuzz (Fuzz.list Fuzzers.wikiCatalogEntry) "AskForWikiCatalog skips when catalog Success" <|
                \summaries ->
                    let
                        dict : Dict Wiki.Slug Wiki.CatalogEntry
                        dict =
                            summaries
                                |> List.map (\s -> ( s.slug, s ))
                                |> Dict.fromList

                        store : Store
                        store =
                            { wikiCatalog = RemoteData.succeed dict
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
                    in
                    store
                        |> Store.perform Frontend.storeConfig Store.AskForWikiCatalog
                        |> Expect.equal ( store, Command.none )
            , Test.test "AskForWikiFrontendDetails skips when slug not in non-empty catalog" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog =
                                RemoteData.succeed
                                    (Dict.singleton "x"
                                        { slug = "x"
                                        , name = "X"
                                        , summary = ""
                                        , active = True
                                        }
                                    )
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
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiFrontendDetails "other")
                        |> Expect.equal
                            ( { store | wikiDetails = Dict.singleton "other" RemoteData.Loading }
                            , Effect.Lamdera.sendToBackend (RequestWikiFrontendDetails "other")
                            )
            , Test.test "AskForWikiFrontendDetails starts load when catalog empty and slug requested" <|
                \() ->
                    let
                        store : Store
                        store =
                            Store.empty
                    in
                    Store.empty
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiFrontendDetails "demo")
                        |> Expect.equal
                            ( { store | wikiDetails = Dict.singleton "demo" RemoteData.Loading }
                            , Effect.Lamdera.sendToBackend (RequestWikiFrontendDetails "demo")
                            )
            , Test.test "AskForWikiTodos starts load from empty" <|
                \() ->
                    Store.empty
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiTodos "demo")
                        |> Expect.equal
                            ( { wikiCatalog = RemoteData.NotAsked
                              , wikiDetails = Dict.empty
                              , publishedPages = Dict.empty
                              , reviewQueues = Dict.empty
                              , myPendingSubmissions = Dict.empty
                              , submissionDetails = Dict.empty
                              , reviewSubmissionDetails = Dict.empty
                              , wikiUsers = Dict.empty
                              , wikiAuditLogs = Dict.empty
                              , wikiTodos =
                                    Dict.singleton "demo" RemoteData.Loading
                              , wikiStats = Dict.empty
                              }
                            , Effect.Lamdera.sendToBackend (RequestWikiTodos "demo")
                            )
            , Test.test "AskForWikiTodos refetches when already Success Ok" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos =
                                Dict.singleton "demo" (RemoteData.succeed (Ok []))
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiTodos "demo")
                        |> Expect.equal
                            ( store
                            , Effect.Lamdera.sendToBackend (RequestWikiTodos "demo")
                            )
            , Test.test "AskForWikiStats starts load from empty" <|
                \() ->
                    Store.empty
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiStats "demo")
                        |> Expect.equal
                            ( { wikiCatalog = RemoteData.NotAsked
                              , wikiDetails = Dict.empty
                              , publishedPages = Dict.empty
                              , reviewQueues = Dict.empty
                              , myPendingSubmissions = Dict.empty
                              , submissionDetails = Dict.empty
                              , reviewSubmissionDetails = Dict.empty
                              , wikiUsers = Dict.empty
                              , wikiAuditLogs = Dict.empty
                              , wikiTodos = Dict.empty
                              , wikiStats =
                                    Dict.singleton "demo" RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestWikiStats "demo")
                            )
            , Test.test "AskForWikiStats refetches when already Success (stale view counts)" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats =
                                Dict.singleton "demo" (RemoteData.succeed Nothing)
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiStats "demo")
                        |> Expect.equal
                            ( store
                            , Effect.Lamdera.sendToBackend (RequestWikiStats "demo")
                            )
            , Test.test "AskForSubmissionDetails starts load from empty" <|
                \() ->
                    Store.empty
                        |> Store.perform Frontend.storeConfig (Store.AskForSubmissionDetails "demo" "sub_1")
                        |> Expect.equal
                            ( { wikiCatalog = RemoteData.NotAsked
                              , wikiDetails = Dict.empty
                              , publishedPages = Dict.empty
                              , reviewQueues = Dict.empty
                              , myPendingSubmissions = Dict.empty
                              , submissionDetails =
                                    Dict.singleton ( "demo", "sub_1" ) RemoteData.Loading
                              , reviewSubmissionDetails = Dict.empty
                              , wikiUsers = Dict.empty
                              , wikiAuditLogs = Dict.empty
                              , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                              }
                            , Effect.Lamdera.sendToBackend (RequestSubmissionDetails "demo" "sub_1")
                            )
            , Test.test "AskForSubmissionDetails refetches after prior error result" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails =
                                Dict.singleton ( "demo", "sub_1" )
                                    (RemoteData.succeed (Err Submission.DetailsNotLoggedIn))
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForSubmissionDetails "demo" "sub_1")
                        |> Expect.equal
                            ( { store
                                | submissionDetails =
                                    Dict.singleton ( "demo", "sub_1" ) RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestSubmissionDetails "demo" "sub_1")
                            )
            , Test.test "AskForSubmissionDetails skips when already Success Ok" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails =
                                Dict.singleton ( "demo", "sub_1" )
                                    (RemoteData.succeed
                                        (Ok
                                            { id = Submission.idFromCounter 1
                                            , status = Submission.Pending
                                            , kindSummary = "New page: x"
                                            , contributionKind = Submission.ContributorKindNewPage
                                            , reviewerNote = Nothing
                                            , conflictContext = Nothing
                                            , compareOriginalMarkdown = "(No published page yet.)"
                                            , compareNewMarkdown = "m"
                                            , maybeNewPageSlug = Just "x"
                                            , maybeEditPageSlug = Nothing
                                            }
                                        )
                                    )
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForSubmissionDetails "demo" "sub_1")
                        |> Expect.equal ( store, Command.none )
            , Test.test "AskForPageFrontendDetails starts load from empty" <|
                \() ->
                    let
                        store : Store
                        store =
                            Store.empty
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForPageFrontendDetails "demo" "home")
                        |> Expect.equal
                            ( { store
                                | publishedPages =
                                    Dict.singleton ( "demo", "home" ) RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestPageFrontendDetails "demo" "home")
                            )
            , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzzers.pageSlug) "AskForPageFrontendDetails skips when already Success" <|
                \( wikiSlug, pageSlug ) ->
                    let
                        key : ( Wiki.Slug, Page.Slug )
                        key =
                            ( wikiSlug, pageSlug )

                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages =
                                Dict.singleton key
                                    (RemoteData.succeed
                                        (Page.frontendDetails (Just "body") [] [] [])
                                    )
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForPageFrontendDetails wikiSlug pageSlug)
                        |> Expect.equal ( store, Command.none )
            , Test.test "AskForReviewQueue starts load from empty" <|
                \() ->
                    let
                        store : Store
                        store =
                            Store.empty
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForReviewQueue "demo")
                        |> Expect.equal
                            ( { store
                                | reviewQueues = Dict.singleton "demo" RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestReviewQueue "demo")
                            )
            , Test.test "AskForReviewQueue skips when already Success Ok" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues =
                                Dict.singleton "demo"
                                    (RemoteData.succeed (Ok []))
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForReviewQueue "demo")
                        |> Expect.equal ( store, Command.none )
            , Test.test "AskForReviewQueue refetches after prior error result" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues =
                                Dict.singleton "demo"
                                    (RemoteData.succeed (Err Submission.ReviewQueueForbidden))
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForReviewQueue "demo")
                        |> Expect.equal
                            ( { store
                                | reviewQueues = Dict.singleton "demo" RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestReviewQueue "demo")
                            )
            , Test.test "AskForMyPendingSubmissions starts load from empty" <|
                \() ->
                    let
                        store : Store
                        store =
                            Store.empty
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForMyPendingSubmissions "demo")
                        |> Expect.equal
                            ( { store
                                | myPendingSubmissions = Dict.singleton "demo" RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestMyPendingSubmissions "demo")
                            )
            , Test.test "AskForMyPendingSubmissions skips when already Success Ok" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions =
                                Dict.singleton "demo"
                                    (RemoteData.succeed (Ok []))
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForMyPendingSubmissions "demo")
                        |> Expect.equal ( store, Command.none )
            , Test.test "AskForMyPendingSubmissions refetches after prior error result" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions =
                                Dict.singleton "demo"
                                    (RemoteData.succeed (Err Submission.MyPendingSubmissionsNotLoggedIn))
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForMyPendingSubmissions "demo")
                        |> Expect.equal
                            ( { store
                                | myPendingSubmissions = Dict.singleton "demo" RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestMyPendingSubmissions "demo")
                            )
            , Test.test "AskForReviewSubmissionDetail starts load from empty" <|
                \() ->
                    Store.empty
                        |> Store.perform Frontend.storeConfig (Store.AskForReviewSubmissionDetail "demo" "sub_1")
                        |> Expect.equal
                            ( { wikiCatalog = RemoteData.NotAsked
                              , wikiDetails = Dict.empty
                              , publishedPages = Dict.empty
                              , reviewQueues = Dict.empty
                              , myPendingSubmissions = Dict.empty
                              , submissionDetails = Dict.empty
                              , reviewSubmissionDetails =
                                    Dict.singleton ( "demo", "sub_1" ) RemoteData.Loading
                              , wikiUsers = Dict.empty
                              , wikiAuditLogs = Dict.empty
                              , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                              }
                            , Effect.Lamdera.sendToBackend (RequestReviewSubmissionDetail "demo" "sub_1")
                            )
            , Test.test "AskForReviewSubmissionDetail refetches after prior error result" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails =
                                Dict.singleton ( "demo", "sub_1" )
                                    (RemoteData.succeed (Err SubmissionReviewDetail.ReviewSubmissionDetailForbidden))
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForReviewSubmissionDetail "demo" "sub_1")
                        |> Expect.equal
                            ( { store
                                | reviewSubmissionDetails =
                                    Dict.singleton ( "demo", "sub_1" ) RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestReviewSubmissionDetail "demo" "sub_1")
                            )
            , Test.test "AskForReviewSubmissionDetail skips when already Success Ok" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails =
                                Dict.singleton ( "demo", "sub_1" )
                                    (RemoteData.succeed
                                        (Ok
                                            (SubmissionReviewDetail.NewPageDiff
                                                { pageSlug = "x"
                                                , proposedMarkdown = "# hi"
                                                }
                                            )
                                        )
                                    )
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForReviewSubmissionDetail "demo" "sub_1")
                        |> Expect.equal ( store, Command.none )
            , Test.test "AskForWikiUsers starts load from empty" <|
                \() ->
                    Store.empty
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiUsers "demo")
                        |> Expect.equal
                            ( { wikiCatalog = RemoteData.NotAsked
                              , wikiDetails = Dict.empty
                              , publishedPages = Dict.empty
                              , reviewQueues = Dict.empty
                              , myPendingSubmissions = Dict.empty
                              , submissionDetails = Dict.empty
                              , reviewSubmissionDetails = Dict.empty
                              , wikiUsers = Dict.singleton "demo" RemoteData.Loading
                              , wikiAuditLogs = Dict.empty
                              , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                              }
                            , Effect.Lamdera.sendToBackend (RequestWikiUsers "demo")
                            )
            , Test.test "AskForWikiUsers skips when already Success Ok" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers =
                                Dict.singleton "demo"
                                    (RemoteData.succeed (Ok []))
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiUsers "demo")
                        |> Expect.equal ( store, Command.none )
            , Test.test "AskForWikiUsers refetches after prior error result" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers =
                                Dict.singleton "demo"
                                    (RemoteData.succeed (Err WikiAdminUsers.Forbidden))
                            , wikiAuditLogs = Dict.empty
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiUsers "demo")
                        |> Expect.equal
                            ( { store
                                | wikiUsers = Dict.singleton "demo" RemoteData.Loading
                              }
                            , Effect.Lamdera.sendToBackend (RequestWikiUsers "demo")
                            )
            , Test.test "AskForWikiAuditLog starts load from empty" <|
                \() ->
                    Store.empty
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter)
                        |> Expect.equal
                            ( { wikiCatalog = RemoteData.NotAsked
                              , wikiDetails = Dict.empty
                              , publishedPages = Dict.empty
                              , reviewQueues = Dict.empty
                              , myPendingSubmissions = Dict.empty
                              , submissionDetails = Dict.empty
                              , reviewSubmissionDetails = Dict.empty
                              , wikiUsers = Dict.empty
                              , wikiAuditLogs =
                                    Dict.singleton "demo"
                                        (Dict.singleton emptyAuditFilterCacheKey RemoteData.Loading)
                              , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                              }
                            , Effect.Lamdera.sendToBackend (RequestWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter)
                            )
            , Test.test "AskForWikiAuditLog skips when already Success Ok" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs =
                                Dict.singleton "demo"
                                    (Dict.singleton emptyAuditFilterCacheKey (RemoteData.succeed (Ok [])))
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter)
                        |> Expect.equal ( store, Command.none )
            , Test.test "AskForWikiAuditLog refetches after prior error result" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs =
                                Dict.singleton "demo"
                                    (Dict.singleton emptyAuditFilterCacheKey (RemoteData.succeed (Err WikiAuditLog.Forbidden)))
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter)
                        |> Expect.equal
                            ( { store
                                | wikiAuditLogs =
                                    Dict.singleton "demo"
                                        (Dict.singleton emptyAuditFilterCacheKey RemoteData.Loading)
                              }
                            , Effect.Lamdera.sendToBackend (RequestWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter)
                            )
            , Test.test "RefreshWikiAuditLog sends even when same filter already Success Ok" <|
                \() ->
                    let
                        store : Store
                        store =
                            { wikiCatalog = RemoteData.NotAsked
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
                            , reviewQueues = Dict.empty
                            , myPendingSubmissions = Dict.empty
                            , submissionDetails = Dict.empty
                            , reviewSubmissionDetails = Dict.empty
                            , wikiUsers = Dict.empty
                            , wikiAuditLogs =
                                Dict.singleton "demo"
                                    (Dict.singleton emptyAuditFilterCacheKey (RemoteData.succeed (Ok [])))
                            , wikiTodos = Dict.empty
                            , wikiStats = Dict.empty
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.RefreshWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter)
                        |> Expect.equal
                            ( { store
                                | wikiAuditLogs =
                                    Dict.singleton "demo"
                                        (Dict.singleton emptyAuditFilterCacheKey RemoteData.Loading)
                              }
                            , Effect.Lamdera.sendToBackend (RequestWikiAuditLog "demo" WikiAuditLog.emptyAuditLogFilter)
                            )
            ]
        ]
