module MarkdownInlineLinkUrlsTest exposing (suite)

import Expect
import MarkdownInlineLinkUrls
import Test exposing (Test)


suite : Test
suite =
    Test.describe "MarkdownInlineLinkUrls"
        [ Test.test "wrapParenContainingDestinations makes Wikipedia-style URL parseable for elm-markdown" <|
            \() ->
                let
                    input : String
                    input =
                        "[On Wikipedia](https://cs.wikipedia.org/wiki/Hani%C4%8Dka_(d%C4%9Blost%C5%99eleck%C3%A1_tvrz)).\n"

                    expected : String
                    expected =
                        "[On Wikipedia](https://cs.wikipedia.org/wiki/Hani%C4%8Dka_%28d%C4%9Blost%C5%99eleck%C3%A1_tvrz%29).\n"
                in
                MarkdownInlineLinkUrls.wrapParenContainingDestinations input
                    |> Expect.equal expected
        ]
