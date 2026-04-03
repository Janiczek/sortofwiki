module WikiTest exposing (suite)

import Dict
import Expect
import Fuzz
import Fuzzers
import Page
import Test exposing (Test)
import Wiki


suite : Test
suite =
    Test.describe "Wiki"
        [ Test.describe "catalogEntry"
            [ Test.test "maps wiki fields" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            { slug = "s"
                            , name = "N"
                            , summary = "Blurb"
                            , active = True
                            , pages = Dict.empty
                            }
                    in
                    Wiki.catalogEntry w
                        |> Expect.equal
                            { slug = "s"
                            , name = "N"
                            , summary = "Blurb"
                            , active = True
                            }
            ]
        , Test.describe "catalogUrlPath"
            [ Test.test "prefixes slug" <|
                \() ->
                    Wiki.catalogUrlPath
                        { slug = "abc"
                        , name = "Abc"
                        , summary = ""
                        , active = True
                        }
                        |> Expect.equal "/w/abc"
            , Test.fuzz Fuzzers.wikiCatalogEntry "catalogUrlPath always starts with /w/" <|
                \w ->
                    Wiki.catalogUrlPath w
                        |> String.startsWith "/w/"
                        |> Expect.equal True
            ]
        , Test.describe "publicCatalogDict"
            [ Test.test "excludes inactive wikis" <|
                \() ->
                    let
                        activeWiki : Wiki.Wiki
                        activeWiki =
                            { slug = "a"
                            , name = "A"
                            , summary = ""
                            , active = True
                            , pages = Dict.empty
                            }

                        inactiveWiki : Wiki.Wiki
                        inactiveWiki =
                            { slug = "b"
                            , name = "B"
                            , summary = ""
                            , active = False
                            , pages = Dict.empty
                            }
                    in
                    Dict.fromList [ ( "a", activeWiki ), ( "b", inactiveWiki ) ]
                        |> Wiki.publicCatalogDict
                        |> Expect.equal
                            (Dict.singleton "a" (Wiki.catalogEntry activeWiki))
            , Test.fuzz (Fuzz.pair Fuzzers.wikiSlug Fuzzers.wikiSlug) "only active slugs appear as keys" <|
                \( slugA, slugB ) ->
                    if slugA == slugB then
                        Expect.pass

                    else
                        let
                            wa : Wiki.Wiki
                            wa =
                                { slug = slugA
                                , name = "NA"
                                , summary = ""
                                , active = True
                                , pages = Dict.empty
                                }

                            wb : Wiki.Wiki
                            wb =
                                { slug = slugB
                                , name = "NB"
                                , summary = ""
                                , active = False
                                , pages = Dict.empty
                                }
                        in
                        Dict.fromList [ ( slugA, wa ), ( slugB, wb ) ]
                            |> Wiki.publicCatalogDict
                            |> Dict.keys
                            |> Expect.equal [ slugA ]
            ]
        , Test.describe "loginUrlPath"
            [ Test.test "demo wiki login" <|
                \() ->
                    Wiki.loginUrlPath "demo"
                        |> Expect.equal "/w/demo/login"
            , Test.fuzz Fuzzers.wikiSlug "ends with /login" <|
                \slug ->
                    Wiki.loginUrlPath slug
                        |> String.endsWith "/login"
                        |> Expect.equal True
            ]
        , Test.describe "publishedPageUrlPath"
            [ Test.test "joins wiki segment and page slug" <|
                \() ->
                    Wiki.publishedPageUrlPath "demo" "home"
                        |> Expect.equal "/w/demo/p/home"
            ]
        , Test.describe "submitNewPageUrlPath"
            [ Test.test "demo wiki new submission form" <|
                \() ->
                    Wiki.submitNewPageUrlPath "demo"
                        |> Expect.equal "/w/demo/submit/new"
            , Test.fuzz Fuzzers.wikiSlug "contains /submit/new" <|
                \slug ->
                    Wiki.submitNewPageUrlPath slug
                        |> String.endsWith "/submit/new"
                        |> Expect.equal True
            ]
        , Test.describe "submitDeleteUrlPath"
            [ Test.test "demo wiki delete request for guides" <|
                \() ->
                    Wiki.submitDeleteUrlPath "demo" "guides"
                        |> Expect.equal "/w/demo/submit/delete/guides"
            , Test.fuzz Fuzzers.wikiSlug "contains /submit/delete/" <|
                \slug ->
                    Wiki.submitDeleteUrlPath slug "home"
                        |> String.startsWith ("/w/" ++ slug ++ "/submit/delete/")
                        |> Expect.equal True
            ]
        , Test.describe "hostAdminWikiDetailUrlPath"
            [ Test.test "demo slug" <|
                \() ->
                    Wiki.hostAdminWikiDetailUrlPath "demo"
                        |> Expect.equal "/admin/wikis/demo"
            , Test.fuzz Fuzzers.wikiSlug "prefixes /admin/wikis/" <|
                \slug ->
                    Wiki.hostAdminWikiDetailUrlPath slug
                        |> String.startsWith "/admin/wikis/"
                        |> Expect.equal True
            ]
        , Test.describe "submissionDetailUrlPath"
            [ Test.test "joins wiki and submission id" <|
                \() ->
                    Wiki.submissionDetailUrlPath "demo" "sub_1"
                        |> Expect.equal "/w/demo/submit/sub_1"
            ]
        , Test.describe "reviewQueueUrlPath"
            [ Test.test "demo wiki review queue" <|
                \() ->
                    Wiki.reviewQueueUrlPath "demo"
                        |> Expect.equal "/w/demo/review"
            , Test.fuzz Fuzzers.wikiSlug "ends with /review" <|
                \slug ->
                    Wiki.reviewQueueUrlPath slug
                        |> String.endsWith "/review"
                        |> Expect.equal True
            ]
        , Test.describe "reviewDetailUrlPath"
            [ Test.test "joins wiki and submission id" <|
                \() ->
                    Wiki.reviewDetailUrlPath "demo" "sub_queue_demo"
                        |> Expect.equal "/w/demo/review/sub_queue_demo"
            ]
        , Test.describe "adminUsersUrlPath"
            [ Test.test "demo wiki admin users" <|
                \() ->
                    Wiki.adminUsersUrlPath "demo"
                        |> Expect.equal "/w/demo/admin/users"
            , Test.fuzz Fuzzers.wikiSlug "contains /admin/users" <|
                \slug ->
                    Wiki.adminUsersUrlPath slug
                        |> String.endsWith "/admin/users"
                        |> Expect.equal True
            ]
        , Test.describe "frontendDetails"
            [ Test.test "lists only published page slugs, sorted" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.fromList
                                    [ ( "a", Page.withPublished "a" "x" )
                                    , ( "z", Page.pendingOnly "z" "draft" )
                                    , ( "m", Page.withPublished "m" "y" )
                                    ]
                                )
                    in
                    Wiki.frontendDetails w
                        |> Expect.equal { pageSlugs = [ "a", "m" ] }
            , Test.fuzz Fuzzers.pageSlug "pending-only wiki yields empty page list" <|
                \slug ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "w" "W" (Dict.singleton slug (Page.pendingOnly slug "d"))
                    in
                    Wiki.frontendDetails w
                        |> Expect.equal { pageSlugs = [] }
            , Test.fuzz (Fuzz.map Dict.fromList (Fuzz.list (Fuzz.pair Fuzzers.pageSlug Fuzzers.page))) "frontendDetails lists exactly published slugs sorted" <|
                \pages ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "w" "W" pages

                        expected : List Page.Slug
                        expected =
                            pages
                                |> Dict.toList
                                |> List.filter (\( _, p ) -> Page.hasPublished p)
                                |> List.map Tuple.first
                                |> List.sort
                    in
                    Wiki.frontendDetails w
                        |> (\d -> d.pageSlugs)
                        |> Expect.equal expected
            ]
        , Test.describe "publishedPageFrontendDetails"
            [ Test.test "returns frontend details when page is published" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "home" (Page.withPublished "home" "body"))
                    in
                    Wiki.publishedPageFrontendDetails "home" w
                        |> Expect.equal
                            (Just (Page.frontendDetails "body" []))
            , Test.test "returns Nothing when page is missing" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "demo" "Demo" Dict.empty
                    in
                    Wiki.publishedPageFrontendDetails "home" w
                        |> Expect.equal Nothing
            , Test.test "returns Nothing for pending-only page" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "x" (Page.pendingOnly "x" "secret"))
                    in
                    Wiki.publishedPageFrontendDetails "x" w
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.pageSlug "Nothing for empty page map" <|
                \pageSlug ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "w" "W" Dict.empty
                    in
                    Wiki.publishedPageFrontendDetails pageSlug w
                        |> Expect.equal Nothing
            , Test.test "uses published markdown only in response" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.singleton "home"
                                    (Page.withPublishedAndPending "home" "published body" "pending body")
                                )
                    in
                    Wiki.publishedPageFrontendDetails "home" w
                        |> Expect.equal
                            (Just (Page.frontendDetails "published body" []))
            , Test.test "includes backlinks from other published pages only" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            Wiki.wikiWithPages "demo"
                                "Demo"
                                (Dict.fromList
                                    [ ( "home", Page.withPublishedAndPending "home" "[g](/w/demo/p/guides)" "[[guides]]" )
                                    , ( "guides", Page.withPublished "guides" "No link to home." )
                                    ]
                                )
                    in
                    Wiki.publishedPageFrontendDetails "guides" w
                        |> Expect.equal
                            (Just
                                (Page.frontendDetails "No link to home." [ "home" ])
                            )
            ]
        ]
