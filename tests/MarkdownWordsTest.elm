module MarkdownWordsTest exposing (suite)

import Expect
import Fuzz
import MarkdownWords
import Test exposing (Test)


suite : Test
suite =
    Test.describe "MarkdownWords"
        [ Test.describe "count"
            [ Test.test "empty" <|
                \() ->
                    MarkdownWords.count ""
                        |> Expect.equal 0
            , Test.test "splits on whitespace" <|
                \() ->
                    MarkdownWords.count "  one two  three\tfour\n"
                        |> Expect.equal 4
            , Test.test "markdown tokens count as words" <|
                \() ->
                    MarkdownWords.count "## Heading"
                        |> Expect.equal 2
            , Test.fuzz Fuzz.string "non-negative (PBT)" <|
                \s ->
                    MarkdownWords.count s
                        |> Expect.atLeast 0
            ]
        ]
