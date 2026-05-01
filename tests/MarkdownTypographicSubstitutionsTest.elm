module MarkdownTypographicSubstitutionsTest exposing (suite)

import Expect
import Markdown.Block as Block
import Markdown.Parser as MarkdownParser
import MarkdownTypographicSubstitutions
import Test exposing (Test)


suite : Test
suite =
    Test.describe "MarkdownTypographicSubstitutions"
        [ Test.describe "postProcessBlocksWithTypographicSubstitutions"
            [ Test.test "replaces double hyphen with en dash in text" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "a -- b" ] ]
                        |> MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "a – b" ] ]
            , Test.test "replaces triple hyphen with em dash in text" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "a --- b" ] ]
                        |> MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "a — b" ] ]
            , Test.test "replaces both triple and double hyphens in same text" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "one --- two -- three" ] ]
                        |> MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "one — two – three" ] ]
            , Test.test "replaces left and right arrows in text" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "go <- then ->" ] ]
                        |> MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "go ← then →" ] ]
            , Test.test "replaces straight double quotes with smart quotes" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "\"hello\" \"world\"" ] ]
                        |> MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "“hello” “world”" ] ]
            , Test.test "replaces apostrophe and single quotes with smart quotes" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "'quote' and don't" ] ]
                        |> MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "‘quote’ and don’t" ] ]
            , Test.test "does not replace hyphens inside code span" <|
                \() ->
                    [ Block.Paragraph [ Block.CodeSpan "a --- b -- c" ] ]
                        |> MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal
                            [ Block.Paragraph [ Block.CodeSpan "a --- b -- c" ] ]
            , Test.test "does not replace arrows or quotes inside code span" <|
                \() ->
                    [ Block.Paragraph [ Block.CodeSpan "<- -> ' \" --- --" ] ]
                        |> MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal
                            [ Block.Paragraph [ Block.CodeSpan "<- -> ' \" --- --" ] ]
            , Test.test "keeps thematic break parsed from standalone line" <|
                \() ->
                    MarkdownParser.parse "---\n"
                        |> Result.map MarkdownTypographicSubstitutions.postProcessBlocksWithTypographicSubstitutions
                        |> Expect.equal (Ok [ Block.ThematicBreak ])
            ]
        ]
