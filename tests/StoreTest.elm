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
import Test exposing (Test)
import Types exposing (ToBackend(..))
import Wiki


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
            , Test.fuzz (Fuzz.list Fuzzers.wikiSummary) "AskForWikiCatalog skips when catalog Success" <|
                \summaries ->
                    let
                        dict : Dict Wiki.Slug Wiki.Summary
                        dict =
                            summaries
                                |> List.map (\s -> ( s.slug, s ))
                                |> Dict.fromList

                        store : Store
                        store =
                            { wikiCatalog = RemoteData.succeed dict
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
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
                                    (Dict.singleton "x" { slug = "x", name = "X" })
                            , wikiDetails = Dict.empty
                            , publishedPages = Dict.empty
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
                                        (Page.frontendDetails { slug = pageSlug, content = "body" })
                                    )
                            }
                    in
                    store
                        |> Store.perform Frontend.storeConfig (Store.AskForPageFrontendDetails wikiSlug pageSlug)
                        |> Expect.equal ( store, Command.none )
            ]
        ]
