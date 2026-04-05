module PageMarkdownTest exposing (suite)

import Fuzz
import Html
import Html.Attributes
import Page
import PageMarkdown
import Test exposing (Test)
import Test.Html.Query
import Test.Html.Selector


wiki : String
wiki =
    "Demo"


allPagesExist : Page.Slug -> Bool
allPagesExist _ =
    True


suite : Test
suite =
    Test.describe "PageMarkdown"
        [ Test.describe "view"
            [ Test.test "renders heading from markdown" <|
                \() ->
                    Page.frontendDetails "## Hello\n" []
                        |> PageMarkdown.view wiki allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "Hello" ]
            , Test.test "adds GitHub-style id on headings for TOC anchors" <|
                \() ->
                    Page.frontendDetails "## Hello\n" []
                        |> PageMarkdown.view wiki allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.id "hello") ]
            , Test.test "renders strong emphasis" <|
                \() ->
                    Page.frontendDetails "**bold**" []
                        |> PageMarkdown.view wiki allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "strong" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "bold" ]
            , Test.test "renders [[page]] as same-wiki published page link" <|
                \() ->
                    Page.frontendDetails "Go to [[guides]]." []
                        |> PageMarkdown.view wiki (\s -> String.toLower s == "guides")
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "guides"
                            , Test.Html.Selector.attribute (Html.Attributes.href "/w/Demo/p/guides")
                            ]
            , Test.test "renders [[slug|label]] with custom link text" <|
                \() ->
                    Page.frontendDetails "[[home|Start here]]" []
                        |> PageMarkdown.view wiki (\s -> String.toLower s == "home")
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "Start here"
                            , Test.Html.Selector.attribute (Html.Attributes.href "/w/Demo/p/home")
                            ]
            , Test.test "does not expand wiki link inside inline code" <|
                \() ->
                    Page.frontendDetails "Use `[[home]]` syntax." []
                        |> PageMarkdown.view wiki allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "code" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "[[home]]" ]
            , Test.test "renders $$...$$ as inline-equation custom element" <|
                \() ->
                    Page.frontendDetails "Inline $$x^2 + y^2$$ math." []
                        |> PageMarkdown.view wiki allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find
                            [ Test.Html.Selector.tag "inline-equation"
                            , Test.Html.Selector.attribute (Html.Attributes.attribute "data-equation" "x^2 + y^2")
                            ]
                        |> Test.Html.Query.has []
            , Test.test "renders $$$...$$$ as block-equation custom element" <|
                \() ->
                    Page.frontendDetails "Before\n\n$$$x^2 + y^2$$$\n\nAfter" []
                        |> PageMarkdown.view wiki allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find
                            [ Test.Html.Selector.tag "block-equation"
                            , Test.Html.Selector.attribute (Html.Attributes.attribute "data-equation" "x^2 + y^2")
                            ]
                        |> Test.Html.Query.has []
            , Test.fuzz (Fuzz.map String.fromInt (Fuzz.intRange 0 999999)) "heading line with numeric title renders as h2 text" <|
                \title ->
                    Page.frontendDetails ("## " ++ title ++ "\n") []
                        |> PageMarkdown.view wiki allPagesExist
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
                        |> PageMarkdown.view wiki allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.attribute (Html.Attributes.href ("/w/Demo/p/" ++ slug))
                            ]
            , Test.test "[[missing]] uses missing-wiki-link styling when slug not published" <|
                \() ->
                    Page.frontendDetails "See [[ghost]]." []
                        |> PageMarkdown.view wiki (\_ -> False)
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "ghost"
                            , Test.Html.Selector.attribute (Html.Attributes.href "/w/Demo/p/ghost")
                            , Test.Html.Selector.class "!text-red-600"
                            ]
            ]
        , Test.describe "viewPreview"
            [ Test.test "uses given container id" <|
                \() ->
                    Html.div []
                        [ PageMarkdown.viewPreview "custom-md-preview" wiki allPagesExist "# Hi\n" ]
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.id "custom-md-preview" ]
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h1" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "Hi" ]
            ]
        ]
