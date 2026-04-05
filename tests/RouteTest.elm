module RouteTest exposing (suite)

import Expect
import Fuzz
import Fuzzers
import Route
import Store
import Test exposing (Test)
import Url
import WikiAuditLog
import WikiRole


suite : Test
suite =
    let
        testCases : List ( String, Route.Route )
        testCases =
            [ ( "https://example.com/w/Demo", Route.WikiHome "Demo" )
            , ( "https://example.com/w/ElmTips", Route.WikiHome "ElmTips" )
            , ( "https://example.com/w/Demo/p/guides", Route.WikiPage "Demo" "guides" )
            , ( "https://example.com/w/Demo/register", Route.WikiRegister "Demo" )
            , ( "https://example.com/w/Demo/login", Route.WikiLogin "Demo" Nothing )
            , ( "https://example.com/w/Demo/submit/new", Route.WikiSubmitNew "Demo" )
            , ( "https://example.com/w/Demo/edit/guides", Route.WikiSubmitEdit "Demo" "guides" )
            , ( "https://example.com/w/Demo/submit/delete/guides", Route.WikiSubmitDelete "Demo" "guides" )
            , ( "https://example.com/w/Demo/submit/sub_1", Route.WikiSubmissionDetail "Demo" "sub_1" )
            , ( "https://example.com/w/Demo/submissions", Route.WikiMySubmissions "Demo" )
            , ( "https://example.com/w/Demo/review", Route.WikiReview "Demo" )
            , ( "https://example.com/w/Demo/review/sub_queue_demo", Route.WikiReviewDetail "Demo" "sub_queue_demo" )
            , ( "https://example.com/w/Demo/admin/users", Route.WikiAdminUsers "Demo" )
            , ( "https://example.com/w/Demo/admin/audit", Route.WikiAdminAudit "Demo" )
            , ( "https://example.com/admin", Route.HostAdmin Nothing )
            , ( "https://example.com/admin/wikis", Route.HostAdminWikis )
            , ( "https://example.com/admin/wikis/new", Route.HostAdminWikiNew )
            , ( "https://example.com/admin/wikis/Demo", Route.HostAdminWikiDetail "Demo" )
            , ( "https://example.com/admin/audit", Route.HostAdminAudit )
            , ( "https://example.com/admin/backup", Route.HostAdminBackup )
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
        (List.concat
            [ testCases |> List.map toTest
            , [ Test.test "empty path is wiki list" <|
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
                        "https://example.com/w/Demo"
                            |> Url.fromString
                            |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                            |> Expect.equal (Just False)
              , Test.test "/w/Demo/guides without /p/ is NotFound" <|
                    \_ ->
                        "https://example.com/w/Demo/guides"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/Demo/guides")
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
              , Test.test "/w/Demo/extra is NotFound" <|
                    \_ ->
                        "https://example.com/w/Demo/extra"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/Demo/extra")
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
              , Test.fuzz Fuzzers.wikiSlug "storeActions WikiRegister asks catalog and details" <|
                    \slug ->
                        Route.storeActions (Route.WikiRegister slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                ]
              , Test.fuzz Fuzzers.wikiSlug "storeActions WikiLogin asks catalog and details" <|
                    \slug ->
                        Route.storeActions (Route.WikiLogin slug Nothing)
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
              , Test.fuzz Fuzzers.wikiSlug "storeActions WikiMySubmissions asks catalog, details, and my pending submissions" <|
                    \slug ->
                        Route.storeActions (Route.WikiMySubmissions slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                , Store.AskForMyPendingSubmissions slug
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
              , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzzers.pageSlug) "storeActions WikiPage asks catalog, details, published page, and my submissions" <|
                    \( wikiSlug, pageSlug ) ->
                        Route.storeActions (Route.WikiPage wikiSlug pageSlug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails wikiSlug
                                , Store.AskForPageFrontendDetails wikiSlug pageSlug
                                , Store.AskForMyPendingSubmissions wikiSlug
                                ]
              , Test.test "storeActions HostAdmin asks nothing" <|
                    \_ ->
                        Route.storeActions (Route.HostAdmin Nothing)
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
                        Route.storeActions (Route.HostAdminWikiDetail "Demo")
                            |> Expect.equal []
              , Test.test "storeActions HostAdminAudit asks nothing" <|
                    \_ ->
                        Route.storeActions Route.HostAdminAudit
                            |> Expect.equal []
              , Test.test "storeActions HostAdminBackup asks nothing" <|
                    \_ ->
                        Route.storeActions Route.HostAdminBackup
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

                                        Route.WikiPage _ _ ->
                                            False

                                        Route.WikiRegister _ ->
                                            False

                                        Route.WikiLogin _ _ ->
                                            False

                                        Route.WikiSubmitNew _ ->
                                            False

                                        Route.WikiSubmitEdit _ _ ->
                                            False

                                        Route.WikiSubmitDelete _ _ ->
                                            False

                                        Route.WikiSubmissionDetail _ _ ->
                                            False

                                        Route.WikiMySubmissions _ ->
                                            False

                                        Route.WikiReview _ ->
                                            False

                                        Route.WikiReviewDetail _ _ ->
                                            False

                                        Route.WikiAdminUsers _ ->
                                            False

                                        Route.WikiAdminAudit _ ->
                                            False

                                        Route.HostAdmin _ ->
                                            False

                                        Route.HostAdminWikis ->
                                            False

                                        Route.HostAdminWikiNew ->
                                            False

                                        Route.HostAdminWikiDetail _ ->
                                            False

                                        Route.HostAdminAudit ->
                                            False

                                        Route.HostAdminBackup ->
                                            False
                                )
                            |> Expect.equal (Just True)
              , Test.test "/w/Demo/register/extra is NotFound" <|
                    \_ ->
                        "https://example.com/w/Demo/register/extra"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/Demo/register/extra")
              , Test.test "/w/Demo/login/extra is NotFound" <|
                    \_ ->
                        "https://example.com/w/Demo/login/extra"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/Demo/login/extra")
              , Test.test "wiki login parses validated redirect query" <|
                    \_ ->
                        "https://example.com/w/Demo/login?redirect=%2Fw%2FDemo%2Freview"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Expect.equal (Just (Route.WikiLogin "Demo" (Just "/w/Demo/review")))
              , Test.test "wiki login drops unsafe redirect query" <|
                    \_ ->
                        "https://example.com/w/Demo/login?redirect=https%3A%2F%2Fevil.com"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Expect.equal (Just (Route.WikiLogin "Demo" Nothing))
              , Test.test "host admin login parses validated redirect query" <|
                    \_ ->
                        "https://example.com/admin?redirect=%2Fadmin%2Fwikis%2Fnew"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Expect.equal (Just (Route.HostAdmin (Just "/admin/wikis/new")))
              , Test.describe "canAccess WikiMySubmissions"
                    [ Test.test "true for untrusted contributor on active wiki" <|
                        \() ->
                            Route.canAccess
                                { hostAdminAuthenticated = False
                                , activeWikiSlug = "Demo"
                                , contributorOnActiveWiki =
                                    Just (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                                }
                                (Route.WikiMySubmissions "Demo")
                                |> Expect.equal True
                    , Test.test "false for trusted contributor on active wiki" <|
                        \() ->
                            Route.canAccess
                                { hostAdminAuthenticated = False
                                , activeWikiSlug = "Demo"
                                , contributorOnActiveWiki = Just WikiRole.TrustedContributor
                                }
                                (Route.WikiMySubmissions "Demo")
                                |> Expect.equal False
                    , Test.test "false for wiki admin on active wiki" <|
                        \() ->
                            Route.canAccess
                                { hostAdminAuthenticated = False
                                , activeWikiSlug = "Demo"
                                , contributorOnActiveWiki = Just WikiRole.Admin
                                }
                                (Route.WikiMySubmissions "Demo")
                                |> Expect.equal False
                    , Test.test "false when wiki slug does not match active wiki" <|
                        \() ->
                            Route.canAccess
                                { hostAdminAuthenticated = False
                                , activeWikiSlug = "ElmTips"
                                , contributorOnActiveWiki =
                                    Just (WikiRole.UntrustedContributor WikiRole.defaultUntrustedContributorCaps)
                                }
                                (Route.WikiMySubmissions "Demo")
                                |> Expect.equal False
                    ]
              ]
            ]
        )
