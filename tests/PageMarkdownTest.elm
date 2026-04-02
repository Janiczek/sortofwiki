module PageMarkdownTest exposing (suite)

import Fuzz
import Html.Attributes
import Page
import PageMarkdown
import Test exposing (Test)
import Test.Html.Query
import Test.Html.Selector


wiki : String
wiki =
    "demo"


suite : Test
suite =
    Test.describe "PageMarkdown"
        [ Test.describe "view"
            [ Test.test "renders heading from markdown" <|
                \() ->
                    Page.frontendDetails "## Hello\n" []
                        |> PageMarkdown.view wiki
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "Hello" ]
            , Test.test "renders strong emphasis" <|
                \() ->
                    Page.frontendDetails "**bold**" []
                        |> PageMarkdown.view wiki
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "strong" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "bold" ]
            , Test.test "renders [[page]] as same-wiki published page link" <|
                \() ->
                    Page.frontendDetails "Go to [[guides]]." []
                        |> PageMarkdown.view wiki
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "guides"
                            , Test.Html.Selector.attribute (Html.Attributes.href "/w/demo/p/guides")
                            ]
            , Test.test "renders [[slug|label]] with custom link text" <|
                \() ->
                    Page.frontendDetails "[[home|Start here]]" []
                        |> PageMarkdown.view wiki
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "Start here"
                            , Test.Html.Selector.attribute (Html.Attributes.href "/w/demo/p/home")
                            ]
            , Test.test "does not expand wiki link inside inline code" <|
                \() ->
                    Page.frontendDetails "Use `[[home]]` syntax." []
                        |> PageMarkdown.view wiki
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "code" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "[[home]]" ]
            , Test.fuzz (Fuzz.map String.fromInt (Fuzz.intRange 0 999999)) "heading line with numeric title renders as h2 text" <|
                \title ->
                    Page.frontendDetails ("## " ++ title ++ "\n") []
                        |> PageMarkdown.view wiki
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text title ]
            , Test.fuzz (Fuzz.intRange 0 99999) "[[slug]] link href uses wiki path segment" <|
                \n ->
                    let
                        slug : String
                        slug =
                            "pg" ++ String.fromInt n
                    in
                    Page.frontendDetails ("[[" ++ slug ++ "]]") []
                        |> PageMarkdown.view wiki
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.attribute (Html.Attributes.href ("/w/demo/p/" ++ slug))
                            ]
            ]
        ]
