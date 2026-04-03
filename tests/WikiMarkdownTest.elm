module WikiMarkdownTest exposing (suite)

import Expect
import Markdown.Block as Block
import Markdown.Parser as MarkdownParser
import MarkdownHeadingSlugs
import Test exposing (Test)
import WikiMarkdown


suite : Test
suite =
    Test.describe "WikiMarkdown"
        [ Test.describe "postProcessBlocksWithWikiLinks"
            [ Test.test "rewrites Text with [[slug]] to Link" <|
                \() ->
                    MarkdownParser.parse "[[x]]"
                        |> Result.map (WikiMarkdown.postProcessBlocksWithWikiLinks "Demo" (\_ -> True))
                        |> Expect.equal
                            (Ok
                                [ Block.Paragraph
                                    [ Block.Link "/w/Demo/p/x" Nothing [ Block.Text "x" ]
                                    ]
                                ]
                            )
            , Test.test "leaves CodeSpan unchanged" <|
                \() ->
                    MarkdownParser.parse "`[[x]]`"
                        |> Result.map (WikiMarkdown.postProcessBlocksWithWikiLinks "Demo" (\_ -> True))
                        |> Expect.equal
                            (Ok [ Block.Paragraph [ Block.CodeSpan "[[x]]" ] ])
            , Test.test "does not duplicate blockquote paragraphs after heading-slug pass" <|
                \() ->
                    MarkdownParser.parse "> line one\n>\n> line two"
                        |> Result.map (WikiMarkdown.postProcessBlocksWithWikiLinks "Demo" (\_ -> True))
                        |> Result.map MarkdownHeadingSlugs.gatherHeadingOccurrences
                        |> Expect.equal
                            (Ok
                                [ ( Block.BlockQuote
                                        [ Block.Paragraph [ Block.Text "line one" ]
                                        , Block.Paragraph [ Block.Text "line two" ]
                                        ]
                                  , Nothing
                                  )
                                ]
                            )
            ]
        ]
