module PageMarkdownTest exposing (suite)

import Fuzz
import Page
import PageMarkdown
import Test exposing (Test)
import Test.Html.Query
import Test.Html.Selector


suite : Test
suite =
    Test.describe "PageMarkdown"
        [ Test.describe "view"
            [ Test.test "renders heading from markdown" <|
                \() ->
                    Page.frontendDetails "## Hello\n" []
                        |> PageMarkdown.view
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "Hello" ]
            , Test.test "renders strong emphasis" <|
                \() ->
                    Page.frontendDetails "**bold**" []
                        |> PageMarkdown.view
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "strong" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "bold" ]
            , Test.fuzz (Fuzz.map String.fromInt (Fuzz.intRange 0 999999)) "heading line with numeric title renders as h2 text" <|
                \title ->
                    Page.frontendDetails ("## " ++ title ++ "\n") []
                        |> PageMarkdown.view
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text title ]
            ]
        ]
