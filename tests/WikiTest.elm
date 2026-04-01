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
        ]
