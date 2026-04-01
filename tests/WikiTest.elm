module WikiTest exposing (suite)

import Dict
import Expect
import Fuzzers
import Page
import Test exposing (Test)
import Wiki


suite : Test
suite =
    Test.describe "Wiki"
        [ Test.describe "catalogUrlPath"
            [ Test.test "prefixes slug" <|
                \() ->
                    Wiki.catalogUrlPath
                        { slug = "abc"
                        , name = "Abc"
                        }
                        |> Expect.equal "/w/abc"
            , Test.fuzz Fuzzers.wikiSummary "catalogUrlPath always starts with /w/" <|
                \w ->
                    Wiki.catalogUrlPath w
                        |> String.startsWith "/w/"
                        |> Expect.equal True
            ]
        , Test.describe "pageIndexUrlPath"
            [ Test.test "demo wiki pages index" <|
                \() ->
                    Wiki.pageIndexUrlPath "demo"
                        |> Expect.equal "/w/demo/pages"
            , Test.fuzz Fuzzers.wikiSlug "ends with /pages" <|
                \slug ->
                    Wiki.pageIndexUrlPath slug
                        |> String.endsWith "/pages"
                        |> Expect.equal True
            ]
        , Test.describe "publishedPageUrlPath"
            [ Test.test "joins wiki segment and page slug" <|
                \() ->
                    Wiki.publishedPageUrlPath "demo" "home"
                        |> Expect.equal "/w/demo/p/home"
            ]
        , Test.describe "publishedPageFrontendDetails"
            [ Test.test "returns frontend details when page exists" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            { slug = "demo"
                            , name = "Demo"
                            , pages =
                                Dict.singleton "home" { slug = "home", content = "body" }
                            }
                    in
                    Wiki.publishedPageFrontendDetails "home" w
                        |> Expect.equal
                            (Just (Page.frontendDetails { slug = "home", content = "body" }))
            , Test.test "returns Nothing when page is missing" <|
                \() ->
                    let
                        w : Wiki.Wiki
                        w =
                            { slug = "demo"
                            , name = "Demo"
                            , pages = Dict.empty
                            }
                    in
                    Wiki.publishedPageFrontendDetails "home" w
                        |> Expect.equal Nothing
            , Test.fuzz Fuzzers.pageSlug "Nothing for empty page map" <|
                \pageSlug ->
                    let
                        w : Wiki.Wiki
                        w =
                            { slug = "w"
                            , name = "W"
                            , pages = Dict.empty
                            }
                    in
                    Wiki.publishedPageFrontendDetails pageSlug w
                        |> Expect.equal Nothing
            ]
        ]
