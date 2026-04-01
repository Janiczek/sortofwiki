module WikiSummaryTest exposing (suite)

import Expect
import Fuzzers
import Test exposing (Test)
import WikiSummary


suite : Test
suite =
    Test.describe "WikiSummary"
        [ Test.describe "unit"
            [ Test.test "catalogUrlPath prefixes slug" <|
                \_ ->
                    let
                        w : WikiSummary.WikiSummary
                        w =
                            { slug = "abc"
                            , name = "Abc"
                            }
                    in
                    WikiSummary.catalogUrlPath w
                        |> Expect.equal "/w/abc"
            ]
        , Test.describe "properties"
            [ Test.fuzz Fuzzers.wikiSummary "catalogUrlPath always starts with /w/" <|
                \w ->
                    WikiSummary.catalogUrlPath w
                        |> String.startsWith "/w/"
                        |> Expect.equal True
            ]
        ]
