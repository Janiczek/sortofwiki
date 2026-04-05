module MarkdownMathTest exposing (suite)

import Expect
import Fuzz
import Markdown.Block as Block
import MarkdownMath
import Test exposing (Test)


suite : Test
suite =
    Test.describe "MarkdownMath"
        [ Test.describe "postProcessBlocksWithEquations"
            [ Test.test "rewrites $$...$$ inside text to inline-equation html" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "Inline $$x^2$$ math" ] ]
                        |> MarkdownMath.postProcessBlocksWithEquations
                        |> Expect.equal
                            [ Block.Paragraph
                                [ Block.Text "Inline "
                                , Block.HtmlInline
                                    (Block.HtmlElement
                                        "inline-equation"
                                        [ { name = "data-equation", value = "x^2" } ]
                                        []
                                    )
                                , Block.Text " math"
                                ]
                            ]
            , Test.test "splits paragraph around $$$...$$$ block math" <|
                \() ->
                    [ Block.Paragraph [ Block.Text "Before $$$x^2$$$ after" ] ]
                        |> MarkdownMath.postProcessBlocksWithEquations
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text "Before " ]
                            , Block.HtmlBlock
                                (Block.HtmlElement
                                    "block-equation"
                                    [ { name = "data-equation", value = "x^2" } ]
                                    []
                                )
                            , Block.Paragraph [ Block.Text " after" ]
                            ]
            , Test.test "leaves code spans unchanged" <|
                \() ->
                    [ Block.Paragraph [ Block.CodeSpan "$$x^2$$" ] ]
                        |> MarkdownMath.postProcessBlocksWithEquations
                        |> Expect.equal
                            [ Block.Paragraph [ Block.CodeSpan "$$x^2$$" ] ]
            , Test.fuzz
                (Fuzz.string
                    |> Fuzz.map (String.filter (\char -> char /= '$'))
                    |> Fuzz.map (\text -> if text == "" then "plain" else text)
                )
                "leaves plain text without delimiters unchanged"
              <|
                \text ->
                    [ Block.Paragraph [ Block.Text text ] ]
                        |> MarkdownMath.postProcessBlocksWithEquations
                        |> Expect.equal
                            [ Block.Paragraph [ Block.Text text ] ]
            ]
        ]
