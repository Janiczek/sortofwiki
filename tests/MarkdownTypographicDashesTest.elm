module MarkdownTypographicDashesTest exposing (suite)

import Expect
import Markdown.Block as Block
import Markdown.Parser as MarkdownParser
import MarkdownTypographicDashes
import Test exposing (Test)


suite : Test
suite =
    Test.describe "MarkdownTypographicDashes"
        [ Test.describe "postProcessBlocksWithTypographicDashes"
            [ Test.test "replaces double hyphen with en dash in text" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "a -- b" ] ]
                        |> MarkdownTypographicDashes.postProcessBlocksWithTypographicDashes
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "a – b" ] ]
            , Test.test "replaces triple hyphen with em dash in text" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "a --- b" ] ]
                        |> MarkdownTypographicDashes.postProcessBlocksWithTypographicDashes
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "a — b" ] ]
            , Test.test "replaces both triple and double hyphens in same text" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "one --- two -- three" ] ]
                        |> MarkdownTypographicDashes.postProcessBlocksWithTypographicDashes
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "one — two – three" ] ]
            , Test.test "does not replace hyphens inside code span" <|
                \() ->
                    [ Block.Paragraph [ Block.CodeSpan "a --- b -- c" ] ]
                        |> MarkdownTypographicDashes.postProcessBlocksWithTypographicDashes
                        |> Expect.equal
                            [ Block.Paragraph [ Block.CodeSpan "a --- b -- c" ] ]
            , Test.test "keeps thematic break parsed from standalone line" <|
                \() ->
                    MarkdownParser.parse "---\n"
                        |> Result.map MarkdownTypographicDashes.postProcessBlocksWithTypographicDashes
                        |> Expect.equal (Ok [ Block.ThematicBreak ])
            ]
        ]
