module WikiTest exposing (suite)

import Expect
import Fuzzers
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
        , Test.describe "articleIndexUrlPath"
            [ Test.test "demo wiki articles index" <|
                \() ->
                    Wiki.articleIndexUrlPath "demo"
                        |> Expect.equal "/w/demo/articles"
            , Test.fuzz Fuzzers.wikiSlug "ends with /articles" <|
                \slug ->
                    Wiki.articleIndexUrlPath slug
                        |> String.endsWith "/articles"
                        |> Expect.equal True
            ]
        , Test.describe "publishedArticleUrlPath"
            [ Test.test "joins wiki, articles segment, and page slug" <|
                \() ->
                    Wiki.publishedArticleUrlPath "demo" "home"
                        |> Expect.equal "/w/demo/articles/home"
            ]
        ]
