module RouteTest exposing (suite)

import Expect
import Fuzz
import Fuzzers
import Route
import Store
import Test exposing (Test)
import Url
import WikiAuditLog


suite : Test
suite =
    let
        testCases : List ( String, Route.Route )
        testCases =
            [ ( "https://example.com/w/demo", Route.WikiHome "demo" )
            , ( "https://example.com/w/elm-tips", Route.WikiHome "elm-tips" )
            , ( "https://example.com/w/demo/pages", Route.WikiPages "demo" )
            , ( "https://example.com/w/demo/p/guides", Route.WikiPage "demo" "guides" )
            , ( "https://example.com/w/demo/pages/", Route.WikiPages "demo" )
            , ( "https://example.com/w/demo/register", Route.WikiRegister "demo" )
            , ( "https://example.com/w/demo/login", Route.WikiLogin "demo" )
            , ( "https://example.com/w/demo/submit/new", Route.WikiSubmitNew "demo" )
            , ( "https://example.com/w/demo/submit/edit/guides", Route.WikiSubmitEdit "demo" "guides" )
            , ( "https://example.com/w/demo/submit/delete/guides", Route.WikiSubmitDelete "demo" "guides" )
            , ( "https://example.com/w/demo/submit/sub_1", Route.WikiSubmissionDetail "demo" "sub_1" )
            , ( "https://example.com/w/demo/review", Route.WikiReview "demo" )
            , ( "https://example.com/w/demo/review/sub_queue_demo", Route.WikiReviewDetail "demo" "sub_queue_demo" )
            , ( "https://example.com/w/demo/admin/users", Route.WikiAdminUsers "demo" )
            , ( "https://example.com/w/demo/admin/audit", Route.WikiAdminAudit "demo" )
            , ( "https://example.com/admin", Route.HostAdmin )
            , ( "https://example.com/admin/wikis", Route.HostAdminWikis )
            , ( "https://example.com/admin/wikis/new", Route.HostAdminWikiNew )
            , ( "https://example.com/admin/wikis/demo", Route.HostAdminWikiDetail "demo" )
            ]

        toTest : ( String, Route.Route ) -> Test
        toTest ( urlString, expectedRoute ) =
            Test.test urlString <|
                \_ ->
                    urlString
                        |> Url.fromString
                        |> Maybe.map Route.fromUrl
                        |> Expect.equal (Just expectedRoute)
    in
    Test.describe "Route"
        ( testCases
            |> List.map toTest
            |> (++)
                [ Test.test "empty path is wiki list" <|
                    \_ ->
                        "https://example.com"
                            |> Url.fromString
                            |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                            |> Expect.equal (Just True)
               , Test.test "slash-only path is wiki list" <|
                    \_ ->
                        "https://example.com/"
                            |> Url.fromString
                            |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                            |> Expect.equal (Just True)
               , Test.test "wiki home path is not wiki list" <|
                    \_ ->
                        "https://example.com/w/demo"
                            |> Url.fromString
                            |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                            |> Expect.equal (Just False)
               , Test.test "/w/demo/guides without /p/ is NotFound" <|
                    \_ ->
                        "https://example.com/w/demo/guides"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/demo/guides")
               , Test.test "wiki pages path is not wiki list" <|
                    \_ ->
                        "https://example.com/w/demo/pages"
                            |> Url.fromString
                            |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                            |> Expect.equal (Just False)
               , Test.test "/w is NotFound" <|
                    \_ ->
                        "https://example.com/w"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w")
               , Test.test "/w/ is NotFound" <|
                    \_ ->
                        "https://example.com/w/"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/")
               , Test.test "/w/demo/extra is NotFound" <|
                    \_ ->
                        "https://example.com/w/demo/extra"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/demo/extra")
               , Test.test "storeActions WikiList asks for catalog" <|
                    \_ ->
                        Route.storeActions Route.WikiList
                            |> Expect.equal [ Store.AskForWikiCatalog ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiHome asks catalog and details" <|
                    \slug ->
                        Route.storeActions (Route.WikiHome slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiPages asks catalog and details" <|
                    \slug ->
                        Route.storeActions (Route.WikiPages slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiRegister asks catalog and details" <|
                    \slug ->
                        Route.storeActions (Route.WikiRegister slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiLogin asks catalog and details" <|
                    \slug ->
                        Route.storeActions (Route.WikiLogin slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiSubmitNew asks catalog and details" <|
                    \slug ->
                        Route.storeActions (Route.WikiSubmitNew slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                ]
               , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzzers.pageSlug) "storeActions WikiSubmitEdit asks catalog, details, and published page" <|
                    \( wikiSlug, pageSlug ) ->
                        Route.storeActions (Route.WikiSubmitEdit wikiSlug pageSlug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails wikiSlug
                                , Store.AskForPageFrontendDetails wikiSlug pageSlug
                                ]
               , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzzers.pageSlug) "storeActions WikiSubmitDelete asks catalog, details, and published page" <|
                    \( wikiSlug, pageSlug ) ->
                        Route.storeActions (Route.WikiSubmitDelete wikiSlug pageSlug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails wikiSlug
                                , Store.AskForPageFrontendDetails wikiSlug pageSlug
                                ]
               , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzz.string) "storeActions WikiSubmissionDetail asks catalog, details, and submission" <|
                    \( wikiSlug, subId ) ->
                        Route.storeActions (Route.WikiSubmissionDetail wikiSlug subId)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails wikiSlug
                                , Store.AskForSubmissionDetails wikiSlug subId
                                ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiReview asks catalog, details, and review queue" <|
                    \slug ->
                        Route.storeActions (Route.WikiReview slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                , Store.AskForReviewQueue slug
                                ]
               , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzz.string) "storeActions WikiReviewDetail asks catalog, details, and review submission detail" <|
                    \( wikiSlug, subId ) ->
                        Route.storeActions (Route.WikiReviewDetail wikiSlug subId)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails wikiSlug
                                , Store.AskForReviewSubmissionDetail wikiSlug subId
                                ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiAdminUsers asks catalog, details, and wiki users" <|
                    \slug ->
                        Route.storeActions (Route.WikiAdminUsers slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                , Store.AskForWikiUsers slug
                                ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiAdminAudit asks catalog, details, and audit log" <|
                    \slug ->
                        Route.storeActions (Route.WikiAdminAudit slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                , Store.AskForWikiAuditLog slug WikiAuditLog.emptyAuditLogFilter
                                ]
               , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzzers.pageSlug) "storeActions WikiPage asks catalog, details, and published page" <|
                    \( wikiSlug, pageSlug ) ->
                        Route.storeActions (Route.WikiPage wikiSlug pageSlug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails wikiSlug
                                , Store.AskForPageFrontendDetails wikiSlug pageSlug
                                ]
               , Test.test "storeActions HostAdmin asks nothing" <|
                    \_ ->
                        Route.storeActions Route.HostAdmin
                            |> Expect.equal []
               , Test.test "storeActions HostAdminWikis asks nothing" <|
                    \_ ->
                        Route.storeActions Route.HostAdminWikis
                            |> Expect.equal []
               , Test.test "storeActions HostAdminWikiNew asks nothing" <|
                    \_ ->
                        Route.storeActions Route.HostAdminWikiNew
                            |> Expect.equal []
               , Test.test "storeActions HostAdminWikiDetail asks nothing" <|
                    \_ ->
                        Route.storeActions (Route.HostAdminWikiDetail "demo")
                            |> Expect.equal []
               , Test.test "storeActions NotFound asks nothing" <|
                    \_ ->
                        Url.fromString "https://example.com/nope"
                            |> Maybe.map (Route.fromUrl >> Route.storeActions)
                            |> Expect.equal (Just [])
               , Test.fuzz Fuzz.string "NotFound preserves url" <|
                    \str ->
                        let
                            path : String
                            path =
                                "missing" ++ str

                            urlString : String
                            urlString =
                                "https://example.com/" ++ path
                        in
                        urlString
                            |> Url.fromString
                            |> Maybe.map
                                (\u ->
                                    case Route.fromUrl u of
                                        Route.NotFound got ->
                                            got == u

                                        Route.WikiList ->
                                            False

                                        Route.WikiHome _ ->
                                            False

                                        Route.WikiPages _ ->
                                            False

                                        Route.WikiPage _ _ ->
                                            False

                                        Route.WikiRegister _ ->
                                            False

                                        Route.WikiLogin _ ->
                                            False

                                        Route.WikiSubmitNew _ ->
                                            False

                                        Route.WikiSubmitEdit _ _ ->
                                            False

                                        Route.WikiSubmitDelete _ _ ->
                                            False

                                        Route.WikiSubmissionDetail _ _ ->
                                            False

                                        Route.WikiReview _ ->
                                            False

                                        Route.WikiReviewDetail _ _ ->
                                            False

                                        Route.WikiAdminUsers _ ->
                                            False

                                        Route.WikiAdminAudit _ ->
                                            False

                                        Route.HostAdmin ->
                                            False

                                        Route.HostAdminWikis ->
                                            False

                                        Route.HostAdminWikiNew ->
                                            False

                                        Route.HostAdminWikiDetail _ ->
                                            False
                                )
                            |> Expect.equal (Just True)
               , Test.test "/w/demo/register/extra is NotFound" <|
                    \_ ->
                        "https://example.com/w/demo/register/extra"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/demo/register/extra")
               , Test.test "/w/demo/login/extra is NotFound" <|
                    \_ ->
                        "https://example.com/w/demo/login/extra"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/demo/login/extra")
               ]
        )
