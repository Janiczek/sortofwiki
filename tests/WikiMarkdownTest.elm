module WikiMarkdownTest exposing (suite)

import Expect
import Markdown.Block as Block
import Markdown.Parser as MarkdownParser
import Test exposing (Test)
import WikiMarkdown


suite : Test
suite =
    Test.describe "WikiMarkdown"
        [ Test.describe "postProcessBlocksWithWikiLinks"
            [ Test.test "rewrites Text with [[slug]] to Link" <|
                \() ->
                    MarkdownParser.parse "[[x]]"
                        |> Result.map (WikiMarkdown.postProcessBlocksWithWikiLinks "demo")
                        |> Expect.equal
                            (Ok
                                [ Block.Paragraph
                                    [ Block.Link "/w/demo/p/x" Nothing [ Block.Text "x" ]
                                    ]
                                ]
                            )
            , Test.test "leaves CodeSpan unchanged" <|
                \() ->
                    MarkdownParser.parse "`[[x]]`"
                        |> Result.map (WikiMarkdown.postProcessBlocksWithWikiLinks "demo")
                        |> Expect.equal
                            (Ok [ Block.Paragraph [ Block.CodeSpan "[[x]]" ] ])
            ]
        ]
